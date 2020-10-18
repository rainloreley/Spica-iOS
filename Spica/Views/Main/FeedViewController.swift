//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import SnapKit
import UIKit

class FeedViewController: UITableViewController {
    var posts = [Post]()
    var loadingHud: JGProgressHUD!
    var latestPostsLoaded = false
    private var contentOffset: CGPoint?

    private var subscriptions = Set<AnyCancellable>()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Feed"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openNewPostView))
        if let splitViewController = splitViewController, !splitViewController.isCollapsed {
            //
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        }

        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    @objc func openSettings() {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        present(vc!, animated: true)
    }

    @objc func openNewPostView() {
        let vc = CreatePostViewController()
        vc.type = .post
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    override func viewDidAppear(_: Bool) {
        loadFeed()
    }

    @objc func loadFeed() {
        if posts.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadFeed()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [self] receivedPosts in
                posts = receivedPosts
                contentOffset = nil
                self.posts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })

                tableView.reloadData()
                if posts.isEmpty {
                    tableView.setEmptyMessage(message: "No posts", subtitle: "When you follow people, their posts should appear here!")
                } else {
                    tableView.restore()
                }
                latestPostsLoaded = true
                self.refreshControl!.endRefreshing()
                self.loadingHud.dismiss()
            }.store(in: &subscriptions)
    }

    func loadMoreFeed(_ before: Date) {
        if latestPostsLoaded, !posts.isEmpty {
            let timestamp = Int(before.timeIntervalSince1970 * 1000)
            loadingHud.show(in: view)
            MicroAPI.default.loadFeed(before: timestamp)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case .failure:
                        break
                    default:
                        break
                    }
                } receiveValue: { [self] posts in
                    DispatchQueue.main.async {
                        var filteredPosts = [Post]()
                        filteredPosts.append(contentsOf: self.posts)
                        for i in posts {
                            if !filteredPosts.contains(where: { $0.id == i.id }) {
                                filteredPosts.append(i)
                            }
                        }
                        self.posts = filteredPosts
                        self.posts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
                        self.tableView.reloadData()
                        if posts.isEmpty {
                            tableView.setEmptyMessage(message: "No posts", subtitle: "When you follow people, their posts should appear here!")
                        } else {
                            tableView.restore()
                        }
                        self.refreshControl!.endRefreshing()
                        self.loadingHud.dismiss()
                    }
                }.store(in: &subscriptions)
        }
    }
}

extension FeedViewController {
    override func numberOfSections(in _: UITableView) -> Int {
        return posts.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
        cell.post = posts[indexPath.section]
        cell.delegate = self

        return cell
    }
}

extension FeedViewController: PostCellDelegate {
    func replyToPost(_ id: String) {
        let vc = CreatePostViewController()
        vc.type = .reply
        vc.delegate = self
        vc.parentID = id
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func reloadData() {
        loadFeed()
    }

    func clickedUser(user: User) {
        let detailVC = UserProfileViewController(style: .insetGrouped)
        detailVC.user = user
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func clickedImage(controller: LightboxController) {
        present(controller, animated: true, completion: nil)
    }
}

extension FeedViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        let contentSize = scrollView.contentSize.height
        let tableSize = scrollView.frame.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let canLoadFromBottom = contentSize > tableSize

        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let difference = maximumOffset - currentOffset

        if canLoadFromBottom, difference <= -120.0 {
            let previousScrollViewBottomInset = scrollView.contentInset.bottom
            scrollView.contentInset.bottom = previousScrollViewBottomInset + 50
            loadMoreFeed(posts.last!.createdAt)
            scrollView.contentInset.bottom = previousScrollViewBottomInset
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let detailVC = PostDetailViewController(style: .insetGrouped)
        detailVC.mainpost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension FeedViewController: CreatePostDelegate {
	func didSendPost(post: Post?) {
		if post != nil {
			let detailVC = PostDetailViewController(style: .insetGrouped)
			detailVC.mainpost = post!
			detailVC.hidesBottomBarWhenPushed = true
			navigationController?.pushViewController(detailVC, animated: true)
		}
	}
}

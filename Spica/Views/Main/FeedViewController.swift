//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import SafariServices
import SnapKit
import UIKit

class FeedViewController: UITableViewController {
    var posts = [Post]()
    var loadingHud: JGProgressHUD!
    var latestPostsLoaded = false
	var imageReloadedCells = [String]()
    private var contentOffset: CGPoint?

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Feed"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openNewPostView)), UIBarButtonItem(image: UIImage(systemName: "text.bubble"), style: .plain, target: self, action: #selector(openUpdateStatus(sender:)))]
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
		tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    var updateStatusViewController: UpdateStatusViewController?

    @objc func openUpdateStatus(sender: UIBarButtonItem) {
        updateStatusViewController = UpdateStatusViewController(title: "Update status", message: "", preferredStyle: .actionSheet)
        if #available(iOS 14.0, *) {
            updateStatusViewController!.rootViewHeight = 350
        } else {
            updateStatusViewController!.rootViewHeight = 500
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        if let popoverController = updateStatusViewController?.popoverPresentationController {
            popoverController.barButtonItem = sender
            /* popoverController.sourceView = view
             popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0) */
        }
        present(updateStatusViewController!, animated: true, completion: nil)
    }

    @objc func keyboardWillAppear() {
        updateStatusViewController?.rootViewHeight = view.frame.height - 64
    }

    @objc func keyboardWillDisappear() {
        // Do something here
        if #available(iOS 14.0, *) {
            updateStatusViewController!.rootViewHeight = 350
        } else {
            updateStatusViewController!.rootViewHeight = 500
        }
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
        print("OFFSET: \(tableView.contentOffset.y)")
        if tableView.contentOffset.y < 200 || posts.isEmpty {
            loadFeed()
        }
    }

    @objc func loadFeed() {
        if posts.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadFeed { [self] result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(receivedPosts):
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
            }
        }
    }

    func loadMoreFeed(_ before: Date) {
        if latestPostsLoaded, !posts.isEmpty {
            let timestamp = Int(before.timeIntervalSince1970 * 1000)
            loadingHud.show(in: view)

            MicroAPI.default.loadFeed(before: timestamp) { [self] result in
                switch result {
                case let .failure(err):
                    DispatchQueue.main.async {
                        self.refreshControl!.endRefreshing()
                        self.loadingHud.dismiss()
                        MicroAPI.default.errorHandling(error: err, caller: self.view)
                    }
                case let .success(posts):
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
                }
            }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView
		cell.indexPath = indexPath
		cell.delegate = self
        cell.post = posts[indexPath.section]

        return cell
    }
}

extension FeedViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension FeedViewController: PostCellDelegate {
	func reloadCell(_ at: IndexPath) {
		if !imageReloadedCells.contains(posts[at.section].id) {
			imageReloadedCells.append(posts[at.section].id)
			DispatchQueue.main.async {
				self.tableView.reloadRows(at: [at], with: .automatic)
			}
		}
	}
	
    func clickedLink(_ url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.delegate = self
        present(vc, animated: true)
    }

    func openPostView(_ type: PostType, preText: String?, preLink: String?, parentID: String?) {
        let vc = CreatePostViewController()
        vc.type = type
        vc.delegate = self
        vc.parentID = parentID
        vc.preText = preText ?? ""
        vc.preLink = preLink
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

    func clickedImage(_ controller: ImageDetailViewController) {
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

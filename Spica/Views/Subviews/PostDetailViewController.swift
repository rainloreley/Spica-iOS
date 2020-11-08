//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
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
import UIKit

class PostDetailViewController: UITableViewController {
    var mainpost: Post!

    var postAncestors = [Post]()
    var postReplies = [Post]()

    var loadingHud: JGProgressHUD!
    var imageReloadedCells = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Post"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(PostDividerCell.self, forCellReuseIdentifier: "dividerCell")
        tableView.register(ReplyButtonCell.self, forCellReuseIdentifier: "replyButtonCell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadPostDetail), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    @objc func loadPostDetail() {
        loadingHud.show(in: view)
        MicroAPI.default.loadPostDetail(post: mainpost) { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(postDetail):
                DispatchQueue.main.async { [self] in
                    mainpost = postDetail.main
                    postAncestors = postDetail.ancestors
                    postReplies = postDetail.replies
                    postAncestors.append(postDetail.main)
                    tableView.reloadData()
                    refreshControl!.endRefreshing()
                    loadingHud.dismiss()

                    if let index = postAncestors.firstIndex(where: { $0.id == mainpost.id }) {
                        tableView.scrollToRow(at: IndexPath(row: 2 * index, section: 0), at: .middle, animated: false)
                    }
                }
            }
        }
    }

    @objc func openReplyView(_: UIButton) {
        if mainpost != nil {
            let vc = CreatePostViewController()
            vc.type = .reply
            vc.delegate = self
            vc.parentID = mainpost.id
            present(UINavigationController(rootViewController: vc), animated: true)
        }
    }

    override func viewDidAppear(_: Bool) {
        loadPostDetail()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return postAncestors.count + postAncestors.count - 1
        } else if section == 1 {
            return 1
        } else {
            return postReplies.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row % 2 == 0 {
                let count = Array(0 ... indexPath.row).filter { !$0.isMultiple(of: 2) }.count
                let post = postAncestors[indexPath.row - count]

                let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

                cell.layer.cornerRadius = 50.0
                cell.indexPath = indexPath
                cell.delegate = self
                cell.post = post

                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "dividerCell", for: indexPath) as! PostDividerCell
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                return cell
            }

        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "replyButtonCell", for: indexPath) as! ReplyButtonCell

            cell.replyBtn.addTarget(self, action: #selector(openReplyView(_:)), for: .touchUpInside)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } else {
            let post = postReplies[indexPath.row]

            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

            cell.indexPath = indexPath
            cell.delegate = self
            cell.post = post

            return cell
        }
    }
}

extension PostDetailViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension PostDetailViewController: PostCellDelegate {
	
	func deletedPost(_ post: Post) {
		navigationController?.popViewController(animated: true)
	}
	
    func reloadCell(_ at: IndexPath) {
        let id = at.section == 0 ? postAncestors[at.row - (Array(0 ... at.row).filter { !$0.isMultiple(of: 2) }.count)].id : postReplies[at.row].id
        if !imageReloadedCells.contains(id) {
            imageReloadedCells.append(id)
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
        loadPostDetail()
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

extension PostDetailViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 1 {
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.hidesBottomBarWhenPushed = true
            if indexPath.section == 0, indexPath.row % 2 == 0 {
                let detailVC = PostDetailViewController(style: .insetGrouped)
                let count = Array(0 ... indexPath.row).filter { !$0.isMultiple(of: 2) }.count
                detailVC.mainpost = Post(id: postAncestors[indexPath.row - count].id)
                navigationController?.pushViewController(detailVC, animated: true)
            } else if indexPath.section == 2 {
                detailVC.mainpost = Post(id: postReplies[indexPath.row].id)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
}

extension PostDetailViewController: CreatePostDelegate {
    func didSendPost(post: Post?) {
        if post != nil {
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.mainpost = post!
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
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
import SPAlert
import SwiftUI
import UIKit

class MentionsViewController: UITableViewController {
    var mentions = [Mention]()

    var loadingHud: JGProgressHUD!
    var imageReloadedCells = [String]()
    var postView: UIHostingController<CreatePostView>?

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Mentions"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewDidAppear(_: Bool) {
        loadMentions()
    }

    @objc func loadMentions() {
        if mentions.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadMentions { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(receivedmentions):
                DispatchQueue.main.async { [self] in
                    mentions = receivedmentions
                    tableView.reloadData()
                    if mentions.isEmpty {
                        tableView.setEmptyMessage(message: "No mentions", subtitle: "Replies to your posts from other people will appear here!")
                    } else {
                        tableView.restore()
                    }
                    refreshControl!.endRefreshing()
                    loadingHud.dismiss()
                    markMentionsAsRead()
                }
            }
        }
    }

    func markMentionsAsRead() {
        MicroAPI.default.markNotificationsAsRead()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return mentions.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

        cell.indexPath = indexPath
        cell.delegate = self
        cell.post = mentions[indexPath.section].post

		if let unreadIndicator = cell.viewWithTag(924) { unreadIndicator.removeFromSuperview() }
        if !mentions[indexPath.section].read {
            let unreadIndicator = UIView()
            unreadIndicator.backgroundColor = .systemBlue
            unreadIndicator.tag = 924
            unreadIndicator.layer.cornerRadius = 10
            cell.addSubview(unreadIndicator)
            unreadIndicator.snp.makeConstraints { make in
                make.top.equalTo(cell.snp.top).offset(8)
                make.width.equalTo(20)
                make.height.equalTo(20)
                make.trailing.equalTo(cell.snp.trailing).offset(-8)
            }
        } else {
            if let unreadIndicator = cell.viewWithTag(924) { unreadIndicator.removeFromSuperview() }
        }

        return cell
    }
}

extension MentionsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension MentionsViewController: PostCellDelegate {
    func updatePost(_ post: Post, reload: Bool, at: IndexPath) {
        guard let postIndexInArray = mentions.firstIndex(where: { $0.post.id == post.id }) else { return }
        mentions[postIndexInArray].post = post
        if reload {
            tableView.reloadRows(at: [at], with: .automatic)
        }
    }

    func deletedPost(_: Post) {
        loadMentions()
    }

    func reloadCell(_ at: IndexPath) {
        if !imageReloadedCells.contains(mentions[at.section].post.id) {
            imageReloadedCells.append(mentions[at.section].post.id)
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
        postView = UIHostingController(rootView: CreatePostView(type: type, controller: .init(delegate: self, parentID: parentID, preText: preText ?? "", preLink: preLink ?? "")))
        postView?.isModalInPresentation = true
        present(UINavigationController(rootViewController: postView!), animated: true)
    }

    func reloadData() {
        loadMentions()
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

extension MentionsViewController: CreatePostDelegate {
    func dismissView() {
        postView!.dismiss(animated: true, completion: nil)
    }

    func didSendPost(post: Post?) {
        if post != nil {
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.mainpost = post!
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension MentionsViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = mentions[indexPath.section].post
        let detailVC = PostDetailViewController(style: .insetGrouped)
        detailVC.mainpost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

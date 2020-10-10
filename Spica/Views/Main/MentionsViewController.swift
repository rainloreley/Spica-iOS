//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import UIKit

class MentionsViewController: UITableViewController {
    var mentions = [Mention]()

    var loadingHud: JGProgressHUD!
    private var subscriptions = Set<AnyCancellable>()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Mentions"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")

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

        MicroAPI.default.loadMentions()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [self] receivedmentions in
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
            }.store(in: &subscriptions)
    }

    func markMentionsAsRead() {
        MicroAPI.default.markNotificationsAsRead()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return mentions.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
        cell.post = mentions[indexPath.section].post
        cell.delegate = self

        if !mentions[indexPath.section].read {
            let unreadIndicator = UIView()
            unreadIndicator.backgroundColor = .systemBlue
            unreadIndicator.tag = 294
            unreadIndicator.layer.cornerRadius = 10
            cell.addSubview(unreadIndicator)
            unreadIndicator.snp.makeConstraints { make in
                make.top.equalTo(cell.snp.top).offset(8)
                make.width.equalTo(20)
                make.height.equalTo(20)
                make.trailing.equalTo(cell.snp.trailing).offset(-8)
            }
        } else {
            if let unreadIndicator = cell.viewWithTag(294) { unreadIndicator.removeFromSuperview() }
        }

        return cell
    }
}

extension MentionsViewController: PostCellDelegate {
    func replyToPost(_ id: String) {
        let vc = CreatePostViewController()
        vc.type = .reply
        vc.delegate = self
        vc.parentID = id
        present(UINavigationController(rootViewController: vc), animated: true)
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

    func clickedImage(controller: LightboxController) {
        present(controller, animated: true, completion: nil)
    }
}

extension MentionsViewController: CreatePostDelegate {
    func didSendPost(post: Post) {
        let detailVC = PostDetailViewController(style: .insetGrouped)
        detailVC.mainpost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
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

//
//  MentionsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import JGProgressHUD
import SPAlert
import UIKit

class MentionsViewController: UIViewController, PostCreateDelegate {
    var tableView: UITableView!

    var mentions = [Post]()

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Notifications"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0
        view.addSubview(tableView)

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
        loadingHud.interactionType = .blockNoTouches

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_: Bool) {
        loadMentions()
    }

    @objc func loadMentions() {
        if mentions.isEmpty {
            loadingHud.show(in: view)
        }
        AllesAPI.default.loadMentions { result in
            switch result {
            case let .success(newPosts):
                DispatchQueue.main.async {
                    self.mentions = newPosts
                    // if isEmpty {
                    self.tableView.reloadData()
                    // }
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                    self.loadingHud.dismiss()
                    self.loadImages()
                }
            case let .failure(apiError):
                DispatchQueue.main.async {
                    EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
                        if self.refreshControl.isRefreshing {
                            self.refreshControl.endRefreshing()
                        }
                        self.loadingHud.dismiss()
                        if apiError.action != nil, apiError.actionParameter != nil {
                            if apiError.action == AllesAPIErrorAction.navigate {
                                if apiError.actionParameter == "login" {
                                    let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                    mySceneDelegate.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func loadImages() {
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()

            for (index, post) in self.mentions.enumerated() {
                dispatchGroup.enter()

                self.mentions[index].author.image = ImageLoader.default.loadImageFromInternet(url: post.author.imageURL)

                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }

                if post.imageURL?.absoluteString != "", post.imageURL != nil {
                    self.mentions[index].image = ImageLoader.default.loadImageFromInternet(url: post.imageURL!)
                } else {
                    self.mentions[index].image = UIImage()
                }

                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }

                dispatchGroup.leave()
            }
        }
    }

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let userByTag = mentions[sender.view!.tag].author
        let vc = UserProfileViewController()
        vc.user = userByTag
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func upvotePost(_ sender: UIButton) {
        let selectedPost = mentions[sender.tag]
        var selectedVoteStatus = 0
        if selectedPost.voteStatus == 1 {
            selectedVoteStatus = 0
        } else {
            selectedVoteStatus = 1
        }

        AllesAPI.default.votePost(post: selectedPost, value: selectedVoteStatus) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if self.mentions[sender.tag].voteStatus == -1 {
                        self.mentions[sender.tag].score += 2
                    } else if selectedVoteStatus == 0 {
                        self.mentions[sender.tag].score -= 1
                    } else {
                        self.mentions[sender.tag].score += 1
                    }
                    self.mentions[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }
                // self.loadMentions()

            case let .failure(apiError):
                DispatchQueue.main.async {
                    EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
                        if apiError.action != nil, apiError.actionParameter != nil {
                            if apiError.action == AllesAPIErrorAction.navigate {
                                if apiError.actionParameter == "login" {
                                    let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                    mySceneDelegate.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @objc func downvotePost(_ sender: UIButton) {
        let selectedPost = mentions[sender.tag]
        var selectedVoteStatus = 0
        if selectedPost.voteStatus == -1 {
            selectedVoteStatus = 0
        } else {
            selectedVoteStatus = -1
        }

        AllesAPI.default.votePost(post: selectedPost, value: selectedVoteStatus) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if self.mentions[sender.tag].voteStatus == 1 {
                        self.mentions[sender.tag].score -= 2
                    } else if selectedVoteStatus == 0 {
                        self.mentions[sender.tag].score += 1
                    } else {
                        self.mentions[sender.tag].score -= 1
                    }
                    self.mentions[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }
                // self.loadMentions()

            case let .failure(apiError):
                DispatchQueue.main.async {
                    EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
                        if apiError.action != nil, apiError.actionParameter != nil {
                            if apiError.action == AllesAPIErrorAction.navigate {
                                if apiError.actionParameter == "login" {
                                    let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                    mySceneDelegate.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */

    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id

        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        mentions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = mentions[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

        cell.delegate = self
        cell.indexPath = indexPath
        cell.post = post

        let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
        cell.pfpImageView.tag = indexPath.row
        cell.pfpImageView.isUserInteractionEnabled = true
        cell.pfpImageView.addGestureRecognizer(tap)

        cell.upvoteButton.tag = indexPath.row
        cell.upvoteButton.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

        cell.downvoteButton.tag = indexPath.row
        cell.downvoteButton.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

        return cell
        /* let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
         let post = mentions[indexPath.row]
         let builtCell = cell.buildCell(cell: cell, post: post, indexPath: indexPath)
         let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
         builtCell.pfpView.tag = indexPath.row
         builtCell.pfpView.addGestureRecognizer(tap)

         cell.upvoteBtn.tag = indexPath.row
         cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)
         cell.delegate = self

         cell.downvoteBtn.tag = indexPath.row
         cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

         return builtCell */
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = mentions[indexPath.row].id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: PostCellViewDelegate {
    func repost(id _: String, username _: String) {
        //
    }

    func replyToPost(id: String) {
        let vc = PostCreateViewController()
        vc.type = .reply
        vc.delegate = self
        vc.parentID = id
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func copyPostID(id: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = id
        SPAlert.present(title: "Copied", preset: .done)
    }

    func deletePost(id: String) {
        EZAlertController.alert("Delete post", message: "Are you sure you want to delete this post?", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { _, int in
            if int == 1 {
                AllesAPI.default.deletePost(id: id) { result in
                    switch result {
                    case .success:
                        self.loadMentions()
                    case let .failure(apiError):
                        DispatchQueue.main.async {
                            EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
                                if self.refreshControl.isRefreshing {
                                    self.refreshControl.endRefreshing()
                                }
                                self.loadingHud.dismiss()
                                if apiError.action != nil, apiError.actionParameter != nil {
                                    if apiError.action == AllesAPIErrorAction.navigate {
                                        if apiError.actionParameter == "login" {
                                            let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                            mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                            mySceneDelegate.window?.makeKeyAndVisible()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func selectedPost(post: String, indexPath _: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func selectedURL(url: String, indexPath _: IndexPath) {
        if UIApplication.shared.canOpenURL(URL(string: url)!) {
            UIApplication.shared.open(URL(string: url)!)
        }
    }

    func selectedUser(username: String, indexPath _: IndexPath) {
        let user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

//
//  PostDetailViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
//

import UIKit

class PostDetailViewController: UIViewController, PostCreateDelegate {
    var selectedPostID: String!
    var selectedPost: Post!
    var tableView: UITableView!

    var postAncestors = [Post]()
    var postReplies = [Post]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Post"
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.register(UINib(nibName: "ReplyButtonCell", bundle: nil), forCellReuseIdentifier: "replyButtonCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0
        view.addSubview(tableView)

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidAppear(_: Bool) {
        loadPostDetail()
    }

    func loadPostDetail() {
        AllesAPI.default.loadPostDetail(postID: selectedPostID) { result in
            switch result {
            case let .success(newPostDetail):
                DispatchQueue.main.async {
                    self.selectedPost = newPostDetail.post
                    self.postAncestors = newPostDetail.ancestors
                    self.postAncestors.append(newPostDetail.post)
                    self.postReplies = newPostDetail.replies
                    self.tableView.reloadData()
                }
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

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let newTag = String(sender.view!.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let row = Int(rowID)!

        let userByTag: User!
        if section == 0 {
            userByTag = postAncestors[row].author
        } else {
            userByTag = postReplies[row].author
        }
        // let userByTag = userPosts[sender.view!.tag].author
        let vc = UserProfileViewController()
        vc.user = userByTag
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func upvotePost(_ sender: UIButton) {
        var subSelectedPost: Post!
        let newTag = String(sender.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let row = Int(rowID)!

        if section == 0 {
            subSelectedPost = postAncestors[row]
        } else {
            subSelectedPost = postReplies[row]
        }

        var selectedVoteStatus = 0
        if subSelectedPost.voteStatus == 1 {
            selectedVoteStatus = 0
        } else {
            selectedVoteStatus = 1
        }

        AllesAPI.default.votePost(post: subSelectedPost, value: selectedVoteStatus) { result in
            switch result {
            case let .success(posts):
                DispatchQueue.main.async {
                    if section == 0 {
                        if self.postAncestors[row].voteStatus == -1 {
                            self.postAncestors[row].score += 2
                        } else if selectedVoteStatus == 0 {
                            self.postAncestors[row].score -= 1
                        } else {
                            self.postAncestors[row].score += 1
                        }
                        self.postAncestors[row].voteStatus = selectedVoteStatus
                    } else {
                        if self.postReplies[row].voteStatus == -1 {
                            self.postReplies[row].score += 2
                        } else if selectedVoteStatus == 0 {
                            self.postReplies[row].score -= 1
                        } else {
                            self.postReplies[row].score += 1
                        }
                        self.postReplies[row].voteStatus = selectedVoteStatus
                    }

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadPostDetail()

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
        var subSelectedPost: Post!
        let newTag = String(sender.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let row = Int(rowID)!

        if section == 0 {
            subSelectedPost = postAncestors[row]
        } else {
            subSelectedPost = postReplies[row]
        }

        var selectedVoteStatus = 0
        if subSelectedPost.voteStatus == -1 {
            selectedVoteStatus = 0
        } else {
            selectedVoteStatus = -1
        }

        AllesAPI.default.votePost(post: subSelectedPost, value: selectedVoteStatus) { result in
            switch result {
            case let .success(posts):
                DispatchQueue.main.async {
                    if section == 0 {
                        if self.postAncestors[row].voteStatus == 1 {
                            self.postAncestors[row].score -= 2
                        } else if selectedVoteStatus == 0 {
                            self.postAncestors[row].score += 1
                        } else {
                            self.postAncestors[row].score -= 1
                        }
                        self.postAncestors[row].voteStatus = selectedVoteStatus
                    } else {
                        if self.postReplies[row].voteStatus == 1 {
                            self.postReplies[row].score -= 2
                        } else if selectedVoteStatus == 0 {
                            self.postReplies[row].score += 1
                        } else {
                            self.postReplies[row].score -= 1
                        }
                        self.postReplies[row].voteStatus = selectedVoteStatus
                    }

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadPostDetail()

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

    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func openReplyView(_: UIButton) {
        if selectedPost != nil {
            let vc = PostCreateViewController()
            vc.type = .reply
            vc.delegate = self
            vc.parentID = selectedPost.id
            present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        /* let userByTag = posts[sender.view!.tag].author
         let vc = UserProfileViewController()
         vc.user = userByTag
         vc.hidesBottomBarWhenPushed = true
         navigationController?.pushViewController(vc, animated: true) */
    }
}

extension PostDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return postAncestors.count
        } else if section == 1 {
            return 1
        } else {
            return postReplies.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell

        let post: Post!
        if indexPath.section == 0 {
            post = postAncestors[indexPath.row]

            var builtCell = cell.buildCell(cell: cell, post: post)
            let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
            builtCell.pfpView.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            builtCell.pfpView.addGestureRecognizer(tap)

            cell.upvoteBtn.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

            cell.downvoteBtn.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

            return builtCell
        } else if indexPath.section == 1 {
            if selectedPost != nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "replyButtonCell", for: indexPath) as! ReplyButtonCell

                cell.replyBtn.addTarget(self, action: #selector(openReplyView(_:)), for: .touchUpInside)
                /* var sendButton = UIButton(type: .system)
                 sendButton.setTitle("Reply", for: .normal)
                 sendButton.setTitleColor(.white, for: .normal)
                 sendButton.backgroundColor = UIColor(named: "PostButtonColor")
                 sendButton.layer.cornerRadius = 12

                 sendButton.addTarget(self, action: #selector(self.openReplyView(_:)), for: .touchUpInside)

                 cell.contentView.addSubview(sendButton)
                 //cell.backgroundView?.addSubview(sendButton)
                 sendButton.snp.makeConstraints { make in
                 	make.bottom.equalTo(cell.contentView.snp.bottom).offset(-50)
                 	make.centerX.equalTo(cell.contentView.snp.centerX)
                 	make.height.equalTo(50)
                 	make.width.equalTo(cell.contentView.snp.width).offset(-32)
                 } */
                return cell
            } else {
                return UITableViewCell()
            }
        } else {
            post = postReplies[indexPath.row]

            var builtCell = cell.buildCell(cell: cell, post: post)
            let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
            builtCell.pfpView.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            builtCell.pfpView.addGestureRecognizer(tap)

            cell.upvoteBtn.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

            cell.downvoteBtn.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

            return builtCell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 1 {
            let detailVC = PostDetailViewController()
            if indexPath.section == 0 {
                detailVC.selectedPostID = postAncestors[indexPath.row].id
            } else if indexPath.section == 2 {
                detailVC.selectedPostID = postReplies[indexPath.row].id
            }

            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

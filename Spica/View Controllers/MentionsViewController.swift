//
//  MentionsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import UIKit

class MentionsViewController: UIViewController {
    var tableView: UITableView!

    var mentions = [Post]()
	
	var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Mentions"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0
        view.addSubview(tableView)
		
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
		tableView.addSubview(refreshControl)

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_: Bool) {
        loadMentions()
    }

    @objc func loadMentions() {
        AllesAPI.default.loadMentions { result in
            switch result {
            case let .success(newPosts):
                DispatchQueue.main.async {
                    self.mentions = newPosts
                    self.tableView.reloadData()
					if self.refreshControl.isRefreshing {
						self.refreshControl.endRefreshing()
					}
                }
            case let .failure(apiError):
                DispatchQueue.main.async {
                    EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
						if self.refreshControl.isRefreshing {
							self.refreshControl.endRefreshing()
						}
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
				case .success(_):
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
                self.loadMentions()

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
				case .success(_):
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
                self.loadMentions()

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
}

extension MentionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        mentions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
        let post = mentions[indexPath.row]
		let builtCell = cell.buildCell(cell: cell, post: post)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
        builtCell.pfpView.tag = indexPath.row
        builtCell.pfpView.addGestureRecognizer(tap)

        cell.upvoteBtn.tag = indexPath.row
        cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

        cell.downvoteBtn.tag = indexPath.row
        cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

        return builtCell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = mentions[indexPath.row].id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

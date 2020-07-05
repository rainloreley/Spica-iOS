//
//  UserProfileViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import UIKit
import SwiftKeychainWrapper

class UserProfileViewController: UIViewController {
    var user: User!
    var tableView: UITableView!
    var userPosts = [Post]()
	
	var signedInUsername: String!
	
	var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        navigationItem.title = "\(user.displayName)"
		signedInUsername = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
        navigationController?.navigationBar.prefersLargeTitles = false
		
		if signedInUsername == user.username {
			navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: nil)
		}

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView?.delegate = self
        tableView?.dataSource = self
        //tableView.bounces = false
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.register(UINib(nibName: "UserHeaderCell", bundle: nil), forCellReuseIdentifier: "userHeaderCell")

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0

        view.addSubview(tableView)
		
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(loadUser), for: .valueChanged)
		tableView.addSubview(refreshControl)
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidAppear(_: Bool) {
		loadUser()
        
    }
	
	@objc func loadUser() {
		DispatchQueue.main.async {
			AllesAPI.default.loadUser(username: self.user.username) { result in
				switch result {
				case let .success(newUser):
					DispatchQueue.main.async {
						self.user = newUser
						self.navigationItem.title = "\(self.user.displayName)"
						self.tableView.reloadData()
						self.loadPosts()
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
	}

    func loadPosts() {
		
        AllesAPI.default.loadUserPosts(user: user) { result in
            switch result {
            case let .success(newPosts):
                DispatchQueue.main.async {
                    self.userPosts = newPosts
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
        let userByTag = userPosts[sender.view!.tag].author
        let vc = UserProfileViewController()
        vc.user = userByTag
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func upvotePost(_ sender: UIButton) {
        let selectedPost = userPosts[sender.tag]
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
                    if self.userPosts[sender.tag].voteStatus == -1 {
                        self.userPosts[sender.tag].score += 2
                    } else if selectedVoteStatus == 0 {
                        self.userPosts[sender.tag].score -= 1
                    } else {
                        self.userPosts[sender.tag].score += 1
                    }
                    self.userPosts[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 1)], with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadPosts()

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
        let selectedPost = userPosts[sender.tag]
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
                    if self.userPosts[sender.tag].voteStatus == 1 {
                        self.userPosts[sender.tag].score -= 2
                    } else if selectedVoteStatus == 0 {
                        self.userPosts[sender.tag].score += 1
                    } else {
                        self.userPosts[sender.tag].score -= 1
                    }
                    self.userPosts[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: sender.tag, section: 1)], with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadPosts()

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

    @objc func followUnfollowUser() {
        AllesAPI.default.performFollowAction(username: user.username, action: user.isFollowing ? .unfollow : .follow) { result in
            switch result {
            case let .success(followStatus):
                DispatchQueue.main.async {
                    self.user.isFollowing = followStatus == .follow ? true : false

                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
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

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        2
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : userPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userHeaderCell", for: indexPath) as! UserHeaderCell
            cell.selectionStyle = .none
            cell.pfpView.image = user.image

            let rectShape = CAShapeLayer()
            rectShape.bounds = cell.contentView.frame
            rectShape.position = cell.contentView.center
            rectShape.path = UIBezierPath(roundedRect: cell.contentView.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 40, height: 40)).cgPath

            cell.contentView.layer.backgroundColor = UIColor(named: "UserBackground")?.cgColor
            cell.contentView.layer.mask = rectShape
			if user.isOnline {
				cell.onlineIndicatorView.backgroundColor = .systemGreen
			}
			else {
				cell.onlineIndicatorView.backgroundColor = .gray
			}

            if user.isPlus {
                // let font:UIFont? = UIFont(name: "Helvetica", size:20)
                let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
                let attrDisplayName = NSMutableAttributedString(string: "\(user.displayName)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: user.displayName.count, length: 1))

                cell.displayNameLbl.attributedText = attrDisplayName
            } else {
                cell.displayNameLbl.text = user.displayName
            }

            cell.usernameLbl.text = "@\(user.username)"

            let boldFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
            let notBoldFont: UIFont = UIFont.systemFont(ofSize: 16)
            let attrRubies = NSMutableAttributedString(string: countString(number: user.rubies, singleText: "Ruby", multiText: "Rubies"), attributes: [.font: notBoldFont])
            attrRubies.setAttributes([.font: boldFont], range: NSRange(location: 0, length: String(user.rubies).count))
            cell.rubiesLbl.attributedText = attrRubies

            let attrFollowers = NSMutableAttributedString(string: countString(number: user.followers, singleText: "Follower", multiText: "Followers"), attributes: [.font: notBoldFont])
            attrFollowers.setAttributes([.font: boldFont], range: NSRange(location: 0, length: String(user.followers).count))
            cell.followerLbl.attributedText = attrFollowers
            cell.aboutTextView.text = user.about
			
			if signedInUsername != user.username {
				cell.followBtn.isEnabled = true
				if user.isFollowing {
					cell.followBtn.setTitle("Following", for: .normal)
					cell.followBtn.backgroundColor = .systemBlue
					cell.followBtn.setTitleColor(.white, for: .normal)
					cell.followBtn.layer.cornerRadius = 12
				} else {
					cell.followBtn.setTitle("Follow", for: .normal)
					cell.followBtn.backgroundColor = .white
					cell.followBtn.setTitleColor(.systemBlue, for: .normal)
					cell.followBtn.layer.cornerRadius = 12
				}

				cell.followBtn.addTarget(self, action: #selector(followUnfollowUser), for: .touchUpInside)
			}
			else {
				cell.followBtn.backgroundColor = .clear
				cell.followBtn.setTitleColor(.clear, for: .normal)
				cell.followBtn.setTitle("", for: .normal)
				cell.followBtn.isEnabled = false
			}

           

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
            let post = userPosts[indexPath.row]
			let builtCell = cell.buildCell(cell: cell, post: post, indexPath: indexPath)
            let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
            builtCell.pfpView.tag = indexPath.row
            builtCell.pfpView.addGestureRecognizer(tap)
            cell.upvoteBtn.tag = indexPath.row
			cell.delegate = self
            cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

            cell.downvoteBtn.tag = indexPath.row
            cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

            return builtCell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let detailVC = PostDetailViewController()
            detailVC.selectedPostID = userPosts[indexPath.row].id
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension UserProfileViewController: PostCellDelegate {
	func selectedPost(post: String, indexPath: IndexPath) {
		let detailVC = PostDetailViewController()
		
		detailVC.selectedPostID = post
		detailVC.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(detailVC, animated: true)
	}
	
	func selectedURL(url: String, indexPath: IndexPath) {
		if UIApplication.shared.canOpenURL(URL(string: url)!) {
			UIApplication.shared.open(URL(string: url)!)
		}
	}
	
	func selectedUser(username: String, indexPath: IndexPath) {
		let user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "")
		let vc = UserProfileViewController()
		vc.user = user
		vc.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(vc, animated: true)
	}
}

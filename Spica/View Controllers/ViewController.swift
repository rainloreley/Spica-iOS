//
//  ViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import SnapKit
import UIKit
import SwiftKeychainWrapper

class ViewController: UIViewController, PostCreateDelegate {
    var tableView: UITableView!
    var createPostBtn: UIButton!
    var posts = [Post]()
	
	var refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
		navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(self.openOwnProfileView))

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0
        view.addSubview(tableView)
		
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
		tableView.addSubview(refreshControl)

        createPostBtn = UIButton(type: .system)
        createPostBtn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        createPostBtn.tintColor = .white
        createPostBtn.backgroundColor = UIColor(named: "PostButtonColor")
        createPostBtn.layer.cornerRadius = 25
        createPostBtn.addTarget(self, action: #selector(openPostCreateView), for: .touchUpInside)

        view.addSubview(createPostBtn)

        createPostBtn.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.right.equalTo(view.snp.right).offset(-16)
        }

        // tableView.rowHeight = UITableView.automaticDimension
    }
	
	@objc func openOwnProfileView() {
		let vc = UserProfileViewController()
		let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
		vc.user = User(id: "", username: username!, displayName: username!, imageURL: URL(string: "https://avatar.alles.cx/u/\(username!)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username!)")!), isFollowing: false, followsMe: false, about: "")
		vc.hidesBottomBarWhenPushed = true
		navigationController?.pushViewController(vc, animated: true)
	}

    @objc func openPostCreateView() {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    public func downloadUIImage(_ url: URL) -> UIImage {
        let data = try? Data(contentsOf: url)
        return UIImage(data: data!)!
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_: Bool) {
        loadFeed()
    }

    @objc func loadFeed() {
        AllesAPI.default.loadFeed { [self] result in
            switch result {
            case let .success(posts):

                DispatchQueue.main.async {
                    self.posts = posts
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
        let userByTag = posts[sender.view!.tag].author
        let vc = UserProfileViewController()
        vc.user = userByTag
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func upvotePost(_ sender: UIButton) {
        let selectedPost = posts[sender.tag]
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
                    if self.posts[sender.tag].voteStatus == -1 {
                        self.posts[sender.tag].score += 2
                    } else if selectedVoteStatus == 0 {
                        self.posts[sender.tag].score -= 1
                    } else {
                        self.posts[sender.tag].score += 1
                    }
                    self.posts[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: sender.tag), with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadFeed()

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
        let selectedPost = posts[sender.tag]
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
                    if self.posts[sender.tag].voteStatus == 1 {
                        self.posts[sender.tag].score -= 2
                    } else if selectedVoteStatus == 0 {
                        self.posts[sender.tag].score += 1
                    } else {
                        self.posts[sender.tag].score -= 1
                    }
                    self.posts[sender.tag].voteStatus = selectedVoteStatus

                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: sender.tag), with: .automatic)
                    self.tableView.endUpdates()
                }
                self.loadFeed()

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
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    func numberOfSections(in _: UITableView) -> Int {
        posts.count
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell
        let post = posts[indexPath.section]

		let builtCell = cell.buildCell(cell: cell, post: post, indexPath: indexPath)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
        builtCell.pfpView.tag = indexPath.section
        builtCell.pfpView.addGestureRecognizer(tap)
		cell.delegate = self

        cell.upvoteBtn.tag = indexPath.section
        cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

        cell.downvoteBtn.tag = indexPath.section
        cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

        return builtCell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = posts[indexPath.section].id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension ViewController: UICollectionViewDelegate {}

enum Section {
    case main
}

extension ViewController: PostCellDelegate {
	
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

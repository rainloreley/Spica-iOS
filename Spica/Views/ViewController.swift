//
//  ViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import JGProgressHUD
import SnapKit
import SPAlert
import SwiftKeychainWrapper
import UIKit

class ViewController: UIViewController, PostCreateDelegate, UITextViewDelegate {
    var tableView: UITableView!
    var createPostBtn: UIButton!
    var posts = [Post]()

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(openOwnProfileView))
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(self.openSettings))

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        // tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108.0
        view.addSubview(tableView)
		
		tableView.snp.makeConstraints { (make) in
			make.top.equalTo(view.snp.top)
			make.leading.equalTo(view.snp.leading)
			make.trailing.equalTo(view.snp.trailing)
			make.bottom.equalTo(view.snp.bottom)
		}

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
        loadingHud.interactionType = .blockNoTouches

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
            make.trailing.equalTo(view.snp.trailing).offset(-16)
        }

        // tableView.rowHeight = UITableView.automaticDimension
    }
	
	@objc func openSettings() {
		let storyboard = UIStoryboard(name: "MainSettings", bundle: nil)
		let vc = storyboard.instantiateInitialViewController() as! UINavigationController
		(vc.viewControllers.first as! MainSettingsViewController).delegate = self
		present(vc, animated: true, completion: nil)
	}

    @objc func openOwnProfileView() {
        let vc = UserProfileViewController()
        let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
        vc.user = User(id: "", username: username!, displayName: username!, imageURL: URL(string: "https://avatar.alles.cx/u/\(username!)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username!)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
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
        if posts.isEmpty {
            loadingHud.show(in: view)
        }
        AllesAPI.default.loadFeed { [self] result in
            switch result {
            case let .success(posts):
				let isEmpty = self.posts.isEmpty
                self.posts = posts
                DispatchQueue.main.async {
					//if isEmpty {
					self.tableView.reloadData()
					//}
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

            for (index, post) in self.posts.enumerated() {
                dispatchGroup.enter()

                if index > self.posts.count - 1 {
                } else {
                    self.posts[index].author.image = ImageLoader.default.loadImageFromInternet(url: post.author.imageURL)

                    DispatchQueue.main.async {
                        self.tableView.beginUpdates()
                        self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                        self.tableView.endUpdates()
                    }

                    if post.imageURL?.absoluteString != "", post.imageURL != nil {
                        self.posts[index].image = ImageLoader.default.loadImageFromInternet(url: post.imageURL!)
                    } else {
                        self.posts[index].image = UIImage()
                    }

                    DispatchQueue.main.async {
                        self.tableView.beginUpdates()
                        self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                        self.tableView.endUpdates()
                    }

                    dispatchGroup.leave()
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
            case .success:
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
                //self.loadFeed()

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
            case .success:
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
                //self.loadFeed()

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
        let post = posts[indexPath.section]

        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

        cell.delegate = self
        cell.indexPath = indexPath
        cell.post = post

        let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
        cell.pfpImageView.tag = indexPath.section
        cell.pfpImageView.isUserInteractionEnabled = true
        cell.pfpImageView.addGestureRecognizer(tap)

        cell.upvoteButton.tag = indexPath.section
        cell.upvoteButton.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

        cell.downvoteButton.tag = indexPath.section
        cell.downvoteButton.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

        return cell
        // let cell = PostCell()

        // cell.buildCell(post: post, indexPath: indexPath)
        /* cell.selectionStyle = .none
         cell.pfpView.image = post.author.image

         if post.image != nil {
         	cell.attachedImageView.image = post.image!

         	cell.attachedImageView.snp.makeConstraints { (make) in
         	 //	make.width.equalTo(self.contentView.snp.width).offset(-80)
         		make.height.equalTo((post.image?.size.height)! / 3)
         	 }
         }

         /* let imageHeight = cell.attachedImageView.image?.size.height
          cell.attachedImageView.snp.makeConstraints { make in

         		make.width.equalTo(self.contentView.snp.width).offset(-80)
         	make.height.equalTo((post.image?.size.height ?? 0) / 3)
         		 //make.height.equalTo(imageHeight!)
         	 } */

         if post.author.isPlus {
         	// let font:UIFont? = UIFont(name: "Helvetica", size:20)
         	let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

         	let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
         	let attrDisplayName = NSMutableAttributedString(string: "\(post.author.displayName)+", attributes: [.font: font!])
         	attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: post.author.displayName.count, length: 1))

         	cell.displayNameLbl.attributedText = attrDisplayName
         } else {
         	cell.displayNameLbl.text = post.author.displayName
         }
         cell.usernameLbl.text = "@\(post.author.username)"
         cell.voteLvl.text = "\(post.score)"
         cell.dateLbl.text = globalDateFormatter.string(from: post.date)
         cell.repliesLbl.text = countString(number: post.repliesCount, singleText: "Reply", multiText: "Replies")
         // contentTextView.text = post.content
         cell.contentTextView.delegate = self

         let attributedText = NSMutableAttributedString(string: "")

         let normalFont: UIFont? = UIFont.systemFont(ofSize: 15)

         let splitContent = post.content.split(separator: " ")
         for word in splitContent {
         	if word.hasPrefix("@"), word.count > 1 {
         		let selectablePart = NSMutableAttributedString(string: String(word) + " ")
         		// let username = String(word).replacingOccurrences(of: ".", with: "")
         		let username = removeSpecialCharsFromString(text: String(word))
         		print("username: \(username)")
         		selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: username.count))
         		// selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
         		selectablePart.addAttribute(.link, value: "user:\(username)", range: NSRange(location: 0, length: username.count))
         		attributedText.append(selectablePart)
         	} else if word.hasPrefix("%"), word.count > 1 {
         		let selectablePart = NSMutableAttributedString(string: String(word) + " ")
         		// let username = String(word).replacingOccurrences(of: ".", with: "")

         		print("madePost: \(word)")

         		selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
         		// selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
         		let postID = word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]
         		selectablePart.addAttribute(.link, value: "post:\(postID)", range: NSRange(location: 0, length: selectablePart.length - 1))
         		attributedText.append(selectablePart)
         	} else if String(word).isValidURL, word.count > 1 {
         		let selectablePart = NSMutableAttributedString(string: String(word) + " ")
         		selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
         		// selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
         		selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
         		attributedText.append(selectablePart)
         	} else {
         		attributedText.append(NSAttributedString(string: word + " "))
         	}
         }

         attributedText.addAttributes([.font: normalFont!], range: NSRange(location: 0, length: attributedText.length))
         cell.contentTextView.attributedText = attributedText
         cell.contentView.resignFirstResponder()

         if post.voteStatus == 1 {
         	cell.upvoteBtn.setTitleColor(.systemGreen, for: .normal)
         	cell.downvoteBtn.setTitleColor(.gray, for: .normal)
         } else if post.voteStatus == -1 {
         	cell.downvoteBtn.setTitleColor(.systemRed, for: .normal)
         	cell.upvoteBtn.setTitleColor(.gray, for: .normal)
         } else {
         	cell.upvoteBtn.setTitleColor(.systemBlue, for: .normal)
         	cell.downvoteBtn.setTitleColor(.systemBlue, for: .normal)
         }

         let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
         cell.pfpView.tag = indexPath.section
         cell.pfpView.addGestureRecognizer(tap)
         cell.delegate = self

         cell.upvoteBtn.tag = indexPath.section
         cell.upvoteBtn.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

         cell.downvoteBtn.tag = indexPath.section
         cell.downvoteBtn.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

         return cell */
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = posts[indexPath.section].id
        detailVC.selectedPost = posts[indexPath.section]
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension ViewController: UICollectionViewDelegate {}

enum Section {
    case main
}

extension ViewController: MainSettingsDelegate {
	func clickedMore(username: String) {
		
        let vc = UserProfileViewController()
		vc.user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
	}
	
	
}

extension ViewController: PostCellViewDelegate {
	func repost(id: String, username: String) {
		let vc = PostCreateViewController()
		vc.type = .post
		vc.delegate = self
		vc.preText = "@\(username)\n\n\n\n%\(id)"
		present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
	}
	
    func replyToPost(id: String) {
        let vc = PostCreateViewController()
        vc.type = .reply
        vc.delegate = self
        vc.parentID = id
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
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
                        self.loadFeed()
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

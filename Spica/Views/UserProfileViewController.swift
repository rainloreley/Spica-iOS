//
//  UserProfileViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Combine
import JGProgressHUD
import SPAlert
import SwiftKeychainWrapper
import UIKit

class UserProfileViewController: UIViewController {
    var user: User!
    var tableView: UITableView!
    var userPosts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    var signedInUsername: String!

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        signedInUsername = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")

        #if targetEnvironment(macCatalyst)
            if traitCollection.userInterfaceIdiom == .mac {
                navigationController?.isToolbarHidden = true
                navigationController?.setNavigationBarHidden(true, animated: false)
            }
        #else
            navigationItem.title = "\(user.displayName)"
            navigationController?.navigationBar.prefersLargeTitles = false
            var rightItems = [UIBarButtonItem]()

            rightItems.append(UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView)))

            if signedInUsername == user.username {
                rightItems.append(UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: nil))
            }

            navigationItem.rightBarButtonItems = rightItems
        #endif

        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(UserHeaderCellView.self, forCellReuseIdentifier: "userHeaderCell")

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }

        // refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadUser), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewWillAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)
            navigationController?.setNavigationBarHidden(true, animated: false)
        #else
            navigationController?.navigationBar.prefersLargeTitles = false
        #endif
    }

    override func viewWillDisappear(_: Bool) {
        #if targetEnvironment(macCatalyst)
            navigationController?.setNavigationBarHidden(false, animated: false)
        #endif
    }

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)
            let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
            if let titleBar = sceneDelegate.window?.windowScene?.titlebar {
                let toolBar = NSToolbar(identifier: "userProfileToolbar")
                toolBar.delegate = self
                titleBar.toolbar = toolBar
            }
        #endif
        loadUser()
    }

    @objc func openPostCreateView() {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.preText = "@\(user.username) "
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc func loadUser() {
        if user == nil || userPosts.isEmpty {
            loadingHud.show(in: view)
        }
        DispatchQueue.main.async { [self] in

            AllesAPI.default.loadUser(username: self.user.username)
                .receive(on: RunLoop.current)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        DispatchQueue.main.async {
                            EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                                if self.refreshControl.isRefreshing {
                                    self.refreshControl.endRefreshing()
                                }
                                self.loadingHud.dismiss()
                                if err.action != nil, err.actionParameter != nil {
                                    if err.action == AllesAPIErrorAction.navigate {
                                        if err.actionParameter == "login" {
                                            let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                            mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                            mySceneDelegate.window?.makeKeyAndVisible()
                                        }
                                    }
                                }
                            }
                        }
                    default: break
                    }
                } receiveValue: { [unowned self] in
                    self.user = $0
                    self.navigationItem.title = "\(self.user.displayName)"
                    #if targetEnvironment(macCatalyst)
                        let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
                        if let titleBar = sceneDelegate.window?.windowScene?.titlebar {
                            let toolBar = NSToolbar(identifier: "userProfileToolbar")
                            toolBar.delegate = self
                            titleBar.toolbar = toolBar
                        }
                    #endif
                    self.loadPfp()
                    self.loadPosts()
                }
                .store(in: &subscriptions)
        }
    }

    func loadPosts() {
        AllesAPI.default.loadUserPosts(user: user)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    DispatchQueue.main.async {
                        EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                            if self.refreshControl.isRefreshing {
                                self.refreshControl.endRefreshing()
                            }
                            self.loadingHud.dismiss()
                            if err.action != nil, err.actionParameter != nil {
                                if err.action == AllesAPIErrorAction.navigate {
                                    if err.actionParameter == "login" {
                                        let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                        mySceneDelegate.window?.makeKeyAndVisible()
                                    }
                                }
                            }
                        }
                    }
                default: break
                }
            } receiveValue: { [unowned self] in

                self.userPosts = $0
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                self.loadingHud.dismiss()
                self.loadImages()
            }
            .store(in: &subscriptions)
    }

    func loadPfp() {
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()

            dispatchGroup.enter()

            self.user.image = ImageLoader.loadImageFromInternet(url: self.user.imageURL)

            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }

            dispatchGroup.leave()
        }
    }

    func loadImages() {
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()

            for (index, post) in self.userPosts.enumerated() {
                if index > self.userPosts.count - 1 {
                } else {
                    dispatchGroup.enter()

                    DispatchQueue.main.async {
                        self.userPosts[index].author.image = ImageLoader.loadImageFromInternet(url: post.author.imageURL)
                    }

                    if index > 10 {
                        if index % 5 == 0 {}
                    }

                    if index % 5 == 0 {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }

                    if let url = post.imageURL {
                        self.userPosts[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        self.userPosts[index].image = UIImage()
                    }

                    if index % 5 == 0 {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }

                    dispatchGroup.leave()
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
        vote(tag: sender.tag, vote: .upvote)
    }

    @objc func downvotePost(_ sender: UIButton) {
        vote(tag: sender.tag, vote: .downvote)
    }

    func vote(tag: Int, vote: VoteType) {
        let selectedPost = userPosts[tag]
        VotePost.default.vote(post: selectedPost, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                        if err.action != nil, err.actionParameter != nil {
                            if err.action == AllesAPIErrorAction.navigate {
                                if err.actionParameter == "login" {
                                    let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                    mySceneDelegate.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                default: break
                }
            } receiveValue: { [unowned self] in
                userPosts[tag].voteStatus = $0.status
                userPosts[tag].score = $0.score
                tableView.beginUpdates()
                tableView.reloadRows(at: [IndexPath(row: tag, section: 1)], with: .automatic)
                tableView.endUpdates()
            }.store(in: &subscriptions)
    }

    @objc func followUnfollowUser() {
        AllesAPI.default.performFollowAction(username: user.username, action: user.isFollowing ? .unfollow : .follow)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                        if err.action != nil, err.actionParameter != nil {
                            if err.action == AllesAPIErrorAction.navigate {
                                if err.actionParameter == "login" {
                                    let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                    mySceneDelegate.window?.makeKeyAndVisible()
                                }
                            }
                        }
                    }
                default: break
                }
            } receiveValue: { [unowned self] in
                self.user.isFollowing = $0 == .follow ? true : false
                if $0 == .follow {
                    self.user.followers += 1
                } else {
                    self.user.followers -= 1
                }
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }.store(in: &subscriptions)
    }
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "userHeaderCell", for: indexPath) as! UserHeaderCellView
            cell.selectionStyle = .none
            cell.user = user
            cell.followButton.addTarget(self, action: #selector(followUnfollowUser), for: .touchUpInside)
            if #available(iOS 13.4, *) {
                cell.followButton.isPointerInteractionEnabled = true
            }
            return cell
        } else {
            let post = userPosts[indexPath.row]

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

extension UserProfileViewController: PostCreateDelegate {
    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension UserProfileViewController: PostCellViewDelegate {
    func repost(id: String, username: String) {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.delegate = self
        vc.preText = "@\(username)\n\n\n\n%\(id)"
        present(UINavigationController(rootViewController: vc), animated: true)
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
        EZAlertController.alert("Delete post", message: "Are you sure you want to delete this post?", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, int in
            if int == 1 {
                AllesAPI.default.deletePost(id: id)
                    .receive(on: RunLoop.main)
                    .sink {
                        switch $0 {
                        case let .failure(err):
                            EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                                if self.refreshControl.isRefreshing {
                                    self.refreshControl.endRefreshing()
                                }
                                self.loadingHud.dismiss()
                                if err.action != nil, err.actionParameter != nil {
                                    if err.action == AllesAPIErrorAction.navigate {
                                        if err.actionParameter == "login" {
                                            let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                            mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                            mySceneDelegate.window?.makeKeyAndVisible()
                                        }
                                    }
                                }
                            }
                        default: break
                        }
                    } receiveValue: { _ in
                        self.loadPosts()
                    }.store(in: &subscriptions)
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
        let user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

#if targetEnvironment(macCatalyst)
    extension UserProfileViewController: NSToolbarDelegate {
        @objc func goBack() {
            navigationController?.popViewController(animated: true)
        }

        func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
            if itemIdentifier == NSToolbarItem.Identifier("back") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("back"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .plain, target: self, action: #selector(goBack)))
                return item
            }
            if itemIdentifier == NSToolbarItem.Identifier("newPost") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("newPost"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView)))
                return item
            } else if itemIdentifier == NSToolbarItem.Identifier("userDisplayname") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("userDisplayname"))
                item.title = user.displayName
                return item
            } else if itemIdentifier == NSToolbarItem.Identifier("reloadData") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("reloadData"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(loadUser)))

                return item
            }
            return nil
        }

        func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [NSToolbarItem.Identifier("back"), NSToolbarItem.Identifier("reloadData"), NSToolbarItem.Identifier("userDisplayname"), NSToolbarItem.Identifier.flexibleSpace, NSToolbarItem.Identifier(rawValue: "newPost")]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return toolbarDefaultItemIdentifiers(toolbar)
        }
    }
#endif

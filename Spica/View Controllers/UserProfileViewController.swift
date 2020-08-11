//
//  UserProfileViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Combine
import JGProgressHUD
import Lightbox
import SPAlert
import SwiftKeychainWrapper
import UIKit

class UserProfileViewController: UIViewController, UserEditDelegate {
    var user: User!
    var imageAnimationAllowed = false
    var tableView: UITableView!
    var loadedPreviously = false
    var userDataLoaded = false
    var toolbarDelegate = ToolbarDelegate()
    private var createPostSubscriber: AnyCancellable?
    private var editProfileSubscriber: AnyCancellable?
    private var navigateBackSubscriber: AnyCancellable?
    var userPosts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    var signedInID: String!

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    var verificationString = ""

    private var subscriptions = Set<AnyCancellable>()

    func didSaveUser(user: UpdateUser) {
        self.user.about = user.about
        self.user.nickname = user.nickname
		self.user.name = user.name
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        loadUser()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hero.isEnabled = true

        loadedPreviously = false

        view.backgroundColor = .systemBackground

		signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

		navigationItem.title = "\(user.name)"
        navigationController?.navigationBar.prefersLargeTitles = false
        var rightItems = [UIBarButtonItem]()

        rightItems.append(UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView)))

		if signedInID == user.id {
            rightItems.append(UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openUserSettings)))
        }

        navigationItem.rightBarButtonItems = rightItems

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(UserHeaderViewCell.self, forCellReuseIdentifier: "headerCellUI")

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }

        refreshControl.addTarget(self, action: #selector(loadUser), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    func setSidebar() {
        if #available(iOS 14.0, *) {
            signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
			if signedInID == user.id {
                if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                    if let sidebar = globalSideBarController {
                        if let collectionView = sidebar.collectionView {
                            collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.account.rawValue), animated: true, scrollPosition: .top)
                        }
                    }
                }
            }
        }
    }

    override func viewWillAppear(_: Bool) {
        setSidebar()

        let notificationCenter = NotificationCenter.default
        createPostSubscriber = notificationCenter.publisher(for: .createPost)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.openPostCreateView()
			})

        navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.navigateBack()
			})

        editProfileSubscriber = notificationCenter.publisher(for: .editProfile)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.openUserSettings()
			})
    }

    @objc func openUserSettings() {
        let vc = UserEditViewController()
        vc.user = user
        vc.delegate = self
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    override func viewWillDisappear(_: Bool) {
        createPostSubscriber?.cancel()
        navigateBackSubscriber?.cancel()
        editProfileSubscriber?.cancel()
    }

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "userprofile")
            toolbarDelegate.navStack = (navigationController?.viewControllers)!
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = toolbar
                titlebar.toolbarStyle = .automatic
            }

            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
        #endif

        setSidebar()
		user = User(name: "Adrian", tag: "0001", plus: true, alles: true, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://pbs.twimg.com/profile_images/1292925137566793738/zYI3tB9P_400x400.jpg")!), imgURL: URL(string: "https://pbs.twimg.com/profile_images/1292925137566793738/zYI3tB9P_400x400.jpg")!, about: "", isOnline: true)
        userDataLoaded = true
        imageAnimationAllowed = true
        // loadUser()
    }

    @objc func openPostCreateView() {
        let vc = PostCreateViewController()
        vc.type = .post
		vc.preText = "@\(user.name) "
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc func loadUser() {
        imageAnimationAllowed = false
        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()

        if user == nil || userPosts.isEmpty {
            loadingHud.show(in: view)
        }
        DispatchQueue.main.async { [self] in

            AllesAPI.default.loadUser(username: self.user.id)
                .receive(on: RunLoop.current)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                            self.loadingHud.dismiss()
                            AllesAPI.default.errorHandling(error: err, caller: self.view)
                        }
                    default: break
                    }
                } receiveValue: { [unowned self] in
                    self.user = $0
                    self.navigationItem.title = "\(self.user.name)"
                    self.loadPfp()
                    self.loadPosts()
                }
                .store(in: &subscriptions)
        }
    }

    func loadPosts() {
        verificationString = ""

        AllesAPI.default.loadUserPosts(user: user)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    DispatchQueue.main.async {
                        self.refreshControl.endRefreshing()
                        self.loadingHud.dismiss()
                        AllesAPI.default.errorHandling(error: err, caller: self.view)
                    }
                default: break
                }
            } receiveValue: { [unowned self] in
                self.userPosts = $0
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                self.loadingHud.dismiss()
                verificationString = randomString(length: 20)
                self.loadImages()
            }
            .store(in: &subscriptions)
    }

    func loadPfp() {
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()

            dispatchGroup.enter()

			self.user.image = ImageLoader.loadImageFromInternet(url: self.user.imgURL!)

            self.userDataLoaded = true
            self.imageAnimationAllowed = true

            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }

            dispatchGroup.leave()
        }
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.global(qos: .background).async { [self] in
            let dispatchGroup = DispatchGroup()
            for (index, post) in userPosts.enumerated() {
                if veri != verificationString { return }
                dispatchGroup.enter()
                if index <= userPosts.count - 1 {
                    if let author = userPosts[index].author {
                        if veri != verificationString { return }
						userPosts[index].author?.image = ImageLoader.loadImageFromInternet(url: author.imgURL!)
                    }
                    if let url = post.imageURL {
                        if veri != verificationString { return }
                        userPosts[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        userPosts[index].image = UIImage()
                    }
                    if index < 5 {
                        if veri != verificationString { return }
                        DispatchQueue.main.async {
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 1)], with: .automatic)
                            self.tableView.endUpdates()
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            DispatchQueue.main.async {
                loadedPreviously = true
                self.tableView.reloadData()
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

                    AllesAPI.default.errorHandling(error: err, caller: self.view)

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
        AllesAPI.default.performFollowAction(username: user.id, action: user.following ? .unfollow : .follow)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [unowned self] in
                self.user.following = $0 == .follow ? true : false
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

extension UserProfileViewController: UserHeaderDelegate {
    func followUnfollowUser(uid _: String) {
        followUnfollowUser()
    }

    func clickedOnFollowerCount() {
        let vc = FollowersFollowingViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCellUI", for: indexPath) as! UserHeaderViewCell
            cell.selectionStyle = .none
            cell.headerController.user = user
            cell.headerController.userDataLoaded = userDataLoaded
            cell.headerController.delegate = self
            cell.headerController.grow = imageAnimationAllowed
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

extension UserProfileViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
    func editBookmark(id: String, action: BookmarkAction) {
        switch action {
        case .add:
            var currentBookmarks = UserDefaults.standard.structArrayData(Bookmark.self, forKey: "savedBookmarks")
            currentBookmarks.append(Bookmark(id: id, added: Date()))
            UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
            SPAlert.present(title: SLocale(.ADDED_ACTION), preset: .done)
        case .remove:
            var currentBookmarks = UserDefaults.standard.structArrayData(Bookmark.self, forKey: "savedBookmarks")
            if let index = currentBookmarks.firstIndex(where: { $0.id == id }) {
                currentBookmarks.remove(at: index)
                UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
                SPAlert.present(title: SLocale(.REMOVED_ACTION), preset: .done)
            } else {
                SPAlert.present(title: SLocale(.ERROR), preset: .error)
            }
        }
    }

    func saveImage(image: UIImage?) {
        if let savingImage = image {
            UIImageWriteToSavedPhotosAlbum(savingImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func image(_: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer) {
        if let error = error {
            SPAlert.present(title: SLocale(.ERROR), message: error.localizedDescription, preset: .error)

        } else {
            SPAlert.present(title: SLocale(.SAVED_ACTION), preset: .done)
        }
    }

    func selectedTag(tag: String, indexPath _: IndexPath) {
        let vc = TagDetailViewController()
        vc.tag = Tag(name: tag, posts: [])
        navigationController?.pushViewController(vc, animated: true)
    }

    func clickedOnImage(controller: LightboxController) {
        present(controller, animated: true, completion: nil)
    }

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
        SPAlert.present(title: SLocale(.COPIED_ACTION), preset: .done)
    }

    func deletePost(id: String) {
        EZAlertController.alert(SLocale(.DELETE_POST), message: SLocale(.DELETE_CONFIRMATION), buttons: [SLocale(.CANCEL), SLocale(.DELETE_ACTION)], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, int in
            if int == 1 {
                AllesAPI.default.deletePost(id: id)
                    .receive(on: RunLoop.main)
                    .sink {
                        switch $0 {
                        case let .failure(err):

                            self.refreshControl.endRefreshing()
                            self.loadingHud.dismiss()
                            AllesAPI.default.errorHandling(error: err, caller: self.view)

                        default: break
                        }
                    } receiveValue: { _ in
                        SPAlert.present(title: SLocale(.DELETED_ACTION), preset: .done)
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
        let vc = UserProfileViewController()
        vc.user = User(name: username, nickname: username)
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

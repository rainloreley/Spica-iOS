//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 29.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import LocalAuthentication
import SnapKit
import SPAlert
import SwiftKeychainWrapper
import UIKit

class TimelineViewController: UIViewController, PostCreateDelegate, UITextViewDelegate {
    var tableView: UITableView!
    var createPostBtn: UIButton!
    var toolbarDelegate = ToolbarDelegate()
    var posts = [Post]()
    var loadedInitialPosts = false

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()
    private var createPostSubscriber: AnyCancellable?
    private var navigateBackSubscriber: AnyCancellable?

    var verificationString = ""
    private var contentOffset: CGPoint?

    var containsCachedElements = false

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        createPostSubscriber?.cancel()
        navigateBackSubscriber?.cancel()
        contentOffset = tableView.contentOffset
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SLocale(.HOME)

        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        let createPostBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView))
        navigationItem.rightBarButtonItems = [createPostBarButtonItem]

        if let splitViewController = splitViewController, !splitViewController.isCollapsed {
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        }

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }
        refreshControl.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches

        createPostBtn = UIButton(type: .system)
        createPostBtn.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        createPostBtn.tintColor = .white
        createPostBtn.backgroundColor = UIColor(named: "PostButtonColor")
        createPostBtn.layer.cornerRadius = 25
        createPostBtn.addTarget(self, action: #selector(openPostCreateView), for: .touchUpInside)
        if #available(iOS 13.4, *) {
            createPostBtn.isPointerInteractionEnabled = true
        }
    }

    @objc func openSettings() {
        let storyboard = UIStoryboard(name: "MainSettings", bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! UINavigationController
        (vc.viewControllers.first as! MainSettingsViewController).delegate = self
        present(vc, animated: true)
    }

    @objc func openOwnProfileView() {
        let vc = UserProfileViewController()

        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name")
        let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag")

        vc.user = User(id: id!, name: name!, tag: tag!)

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func openPostCreateView() {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func setSidebar() {
        if #available(iOS 14.0, *) {
            if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                if let sidebar = globalSideBarController {
                    navigationController?.viewControllers = [self]
                    if let collectionView = sidebar.collectionView {
                        collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.home.rawValue), animated: true, scrollPosition: .top)
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "timeline")
            toolbarDelegate.navStack = (navigationController?.viewControllers)!
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = toolbar
                titlebar.toolbarStyle = .automatic
                titlebar.titleVisibility = .visible
            }

            navigationController?.setNavigationBarHidden(true, animated: animated)
            navigationController?.setToolbarHidden(true, animated: animated)
        #endif
        requestBiometricAuth()
        setSidebar()

        loadVersion()
        loadPrivacyPolicy()
        loadFeed()
    }

    func loadPrivacyPolicy() {
        SpicAPI.getPrivacyPolicy()
            .receive(on: RunLoop.current)
            .sink {
                switch $0 {
                case .failure:
                    return
                default: break
                }
            } receiveValue: { privacyPolicy in
                if privacyPolicy.markdown != "" {
                    let vc = NewPrivacyPolicyViewController()
                    vc.privacyPolicy = privacyPolicy
                    vc.isModalInPresentation = true
                    self.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
            .store(in: &subscriptions)
    }

    func loadVersion() {
        SpicAPI.getVersion()
            .receive(on: RunLoop.current)
            .sink {
                switch $0 {
                case .failure:
                    return
                default: break
                }
            } receiveValue: { version in
                if let currentBuildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    let currentBuild = Int(currentBuildString)!
                    if currentBuild < version.reqBuild {
                        DispatchQueue.main.async {
                            EZAlertController.alert("Outdated app", message: "We detected that you're using an old version of the app. This is usually not a problem but we made some important changes. Please update the app. It will now exit", actions: [UIAlertAction(title: "Ok", style: .default, handler: { _ in
                                exit(0)
							})])
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    @objc func loadFeed() {
        verificationString = ""
        if posts.isEmpty { loadingHud.show(in: view) }
        AllesAPI.default.loadFeed()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [self] posts in
                // self.posts = Array(Set(self.posts + posts))
                if self.refreshControl.isRefreshing {
                    self.posts = posts
                    contentOffset = nil
                } else {
                    var filteredPosts = [Post]()
                    filteredPosts.append(contentsOf: self.posts)
                    for i in posts {
                        if !filteredPosts.contains(where: { $0.id == i.id }) {
                            filteredPosts.append(i)
                        }
                    }

                    self.posts = filteredPosts
                }
                self.posts.sort(by: { $0.created.compare($1.created) == .orderedDescending })

                self.tableView.reloadData()
                if self.posts.isEmpty {
                    self.tableView.setEmptyMessage(message: SLocale(.TIMELINE_EMPTY_TITLE), subtitle: SLocale(.TIMELINE_EMPTY_SUBTITLE))
                } else {
                    self.tableView.restore()
                }
                self.refreshControl.endRefreshing()
                self.loadingHud.dismiss()
                verificationString = randomString(length: 30)
                self.loadImages(posts)

                if let contentOffset = self.contentOffset {
                    self.tableView.setContentOffset(contentOffset, animated: true)
                }

            }.store(in: &subscriptions)
    }

    func requestBiometricAuth() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
        let sceneRootView = sceneDelegate.window?.rootViewController?.view!

        if UserDefaults.standard.bool(forKey: "biometricAuthEnabled"), appDelegate?.sessionAuthorized == false {
            let blurStyle = traitCollection.userInterfaceStyle == .dark ? UIBlurEffect.Style.dark : UIBlurEffect.Style.light
            let blurEffect = UIBlurEffect(style: blurStyle)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurEffectView.alpha = 1.0
            blurEffectView.tag = 395
            if sceneRootView!.viewWithTag(395) != nil {
            } else {
                sceneRootView!.addSubview(blurEffectView)
                blurEffectView.snp.makeConstraints { make in
                    make.top.equalTo(sceneRootView!.snp.top)
                    make.leading.equalTo(sceneRootView!.snp.leading)
                    make.bottom.equalTo(sceneRootView!.snp.bottom)
                    make.trailing.equalTo(sceneRootView!.snp.trailing)
                }
            }

            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: SLocale(.UNLOCK_SPICA)) { success, _ in
                    if success {
                        DispatchQueue.main.async {
                            appDelegate!.sessionAuthorized = true
                            UIView.animate(withDuration: 0.3, animations: {
                                blurEffectView.alpha = 0.0
										}) { _ in
                                if let blurTag = sceneRootView!.viewWithTag(395) {
                                    blurTag.removeFromSuperview()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            EZAlertController.alert(SLocale(.BIOMETRIC_AUTH_FAILED), message: SLocale(.PLEASE_TRY_AGAIN), acceptMessage: SLocale(.RETRY_ACTION)) {
                                self.requestBiometricAuth()
                            }
                        }
                    }
                }
            } else {
                var type = "FaceID / TouchID"
                let biometric = biometricType()
                switch biometric {
                case .face:
                    type = "FaceID"
                case .touch:
                    type = "TouchID"
                case .none:
                    type = "FaceID / TouchID"
                }
                EZAlertController.alert(SLocale(.DEVICE_ERROR), message: String(format: SLocale(.BIOMETRIC_DEVICE_NOTAVAILABLE), "\(type)", "\(type)"), acceptMessage: SLocale(.RETRY_ACTION)) {
                    self.requestBiometricAuth()
                }
            }
        }
    }

    func loadImages(_ forPosts: [Post]) {
        DispatchQueue.global(qos: .utility).async { [self] in
            for post in forPosts {
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index].author?.image = ImageLoader.loadImageFromInternet(url: (post.author?.imgURL)!)
                    if let mentionedPost = post.mentionedPost {
                        posts[index].mentionedPost?.author?.image = ImageLoader.loadImageFromInternet(url: (mentionedPost.author?.imgURL)!)
                    }
                    if let url = post.imageURL {
                        posts[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        posts[index].image = UIImage()
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.posts.isEmpty {
                    self.tableView.setEmptyMessage(message: SLocale(.TIMELINE_EMPTY_TITLE), subtitle: SLocale(.TIMELINE_EMPTY_SUBTITLE))
                } else {
                    self.tableView.restore()
                }
                loadedInitialPosts = true
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
        vote(tag: sender.tag, vote: .upvote)
    }

    @objc func downvotePost(_ sender: UIButton) {
        vote(tag: sender.tag, vote: .downvote)
    }

    func vote(tag: Int, vote: VoteType) {
        let selectedPost = posts[tag]
        VotePost.default.vote(post: selectedPost, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [unowned self] in
                posts[tag].voted = $0.status
                posts[tag].score = $0.score
                tableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .automatic)
            }.store(in: &subscriptions)
    }

    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func loadEvenMorePosts(_ beforeDate: Date) {
        if loadedInitialPosts, !posts.isEmpty {
            let timestamp = Int(beforeDate.timeIntervalSince1970 * 1000)
            verificationString = ""
            if posts.isEmpty { loadingHud.show(in: view) }
            AllesAPI.default.loadFeed(loadBefore: timestamp)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        self.refreshControl.endRefreshing()
                        self.loadingHud.dismiss()
                        AllesAPI.default.errorHandling(error: err, caller: self.view)

                    default: break
                    }
                } receiveValue: { [self] posts in
                    DispatchQueue.main.async {
                        var filteredPosts = [Post]()
                        filteredPosts.append(contentsOf: self.posts)
                        for i in posts {
                            if !filteredPosts.contains(where: { $0.id == i.id }) {
                                filteredPosts.append(i)
                            }
                        }

                        self.posts = filteredPosts
                        self.posts.sort(by: { $0.created.compare($1.created) == .orderedDescending })
                        self.tableView.reloadData()
                        if self.posts.isEmpty {
                            self.tableView.setEmptyMessage(message: SLocale(.TIMELINE_EMPTY_TITLE), subtitle: SLocale(.TIMELINE_EMPTY_SUBTITLE))
                        } else {
                            self.tableView.restore()
                        }
                        // self.posts = Array(Set(self.posts + posts))
                        self.refreshControl.endRefreshing()
                        self.loadingHud.dismiss()
                        self.loadImages(posts)
                    }

                }.store(in: &subscriptions)
        }
    }
}

extension TimelineViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView
        let post = posts[indexPath.row]

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

extension TimelineViewController: UITableViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        let contentSize = scrollView.contentSize.height
        let tableSize = scrollView.frame.size.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let canLoadFromBottom = contentSize > tableSize

        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let difference = maximumOffset - currentOffset

        if canLoadFromBottom, difference <= -120.0 {
            let previousScrollViewBottomInset = scrollView.contentInset.bottom
            scrollView.contentInset.bottom = previousScrollViewBottomInset + 50
            loadEvenMorePosts(posts.last!.created)
            scrollView.contentInset.bottom = previousScrollViewBottomInset
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        let detailVC = PostDetailViewController()
        detailVC.selectedPost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension TimelineViewController: MainSettingsDelegate {
    func clickedMore(uid: String) {
        let vc = UserProfileViewController()

        vc.user = User(id: uid)

        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension TimelineViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
    func clickedOnMiniPost(id: String, miniPost _: MiniPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

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
        #if targetEnvironment(macCatalyst)
            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }

            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
        #endif
        present(controller, animated: true, completion: nil)
    }

    func repost(id: String, uid: String) {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.delegate = self
        vc.preText = "@\(uid)\n\n\n\n%\(id)"
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
        EZAlertController.alert(SLocale(.DELETE_POST), message: SLocale(.DELETE_CONFIRMATION), buttons: [SLocale(.CANCEL), SLocale(.DELETE_ACTION)], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, index in
            guard index == 1 else { return }

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
                    self.loadFeed()
                }.store(in: &subscriptions)
        }
    }

    func selectedPost(post: String, indexPath _: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func selectedURL(url: String, indexPath _: IndexPath) {
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func selectedUser(id: String, indexPath _: IndexPath) {
        let vc = UserProfileViewController()

        /* let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
         let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name")
         let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag") */

        vc.user = User(id: id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

#if targetEnvironment(macCatalyst)
    extension TimelineViewController: NSToolbarDelegate {
        func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
            if itemIdentifier == NSToolbarItem.Identifier("newPost") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("newPost"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView)))
                return item
            } else if itemIdentifier == NSToolbarItem.Identifier("userProfile") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("userProfile"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(openOwnProfileView)))
                return item
            } else if itemIdentifier == NSToolbarItem.Identifier("reloadData") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("reloadData"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(loadFeed)))

                return item
            }
            return nil
        }

        func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [NSToolbarItem.Identifier("reloadData"), NSToolbarItem.Identifier.flexibleSpace, NSToolbarItem.Identifier("userProfile"), NSToolbarItem.Identifier(rawValue: "newPost")]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return toolbarDefaultItemIdentifiers(toolbar)
        }
    }
#endif

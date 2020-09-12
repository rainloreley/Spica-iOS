//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 30.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import SPAlert
import UIKit

class MentionsViewController: UIViewController, PostCreateDelegate {
    var tableView: UITableView!
    var toolbarDelegate = ToolbarDelegate()

    var mentions = [PostNotification]()

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()
    private var navigateBackSubscriber: AnyCancellable?

    var verificationString = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = SLocale(.NOTIFICATIONS)
        navigationController?.navigationBar.prefersLargeTitles = true

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

        refreshControl.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    func setSidebar() {
        if #available(iOS 14.0, *) {
            if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                if let sidebar = globalSideBarController {
                    navigationController?.viewControllers = [self]
                    if let collectionView = sidebar.collectionView {
                        collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.mentions.rawValue), animated: true, scrollPosition: .top)
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_: Bool) {
        navigateBackSubscriber?.cancel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSidebar()

        navigationController?.navigationBar.prefersLargeTitles = true

        let notificationCenter = NotificationCenter.default
        navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.navigateBack()
			})
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "mentions")
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

        setSidebar()
        loadMentions()
    }

    @objc func loadMentions() {
        if mentions.isEmpty {
            loadingHud.show(in: view)
        }

        verificationString = ""

        AllesAPI.default.loadMentions()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { mentions in
                DispatchQueue.main.async {
                    self.mentions = mentions
                    self.tableView.reloadData()
                    if self.mentions.isEmpty {
                        self.tableView.setEmptyMessage(message: SLocale(.NOTIFICATIONS_EMPTY_TITLE), subtitle: SLocale(.NOTIFICATIONS_EMPTY_SUBTITLE))
                    } else {
                        self.tableView.restore()
                    }
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()

                    self.verificationString = randomString(length: 30)
                    self.loadImages()
                    self.markAsRead()
                }

            }.store(in: &subscriptions)
    }

    func markAsRead() {
        AllesAPI.default.markNotificationsAsRead()
    }

    func loadImages() {
        DispatchQueue.global(qos: .utility).async { [self] in
            for (index, mention) in mentions.enumerated() {
                mentions[index].post.author?.image = ImageLoader.loadImageFromInternet(url: (mention.post.author?.imgURL)!)
                if let mentionedPost = mention.post.mentionedPost {
                    mentions[index].post.mentionedPost?.author?.image = ImageLoader.loadImageFromInternet(url: (mentionedPost.author?.imgURL)!)
                }
                if let url = mention.post.imageURL {
                    mentions[index].post.image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    mentions[index].post.image = UIImage()
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.mentions.isEmpty {
                    self.tableView.setEmptyMessage(message: SLocale(.NOTIFICATIONS_EMPTY_TITLE), subtitle: SLocale(.NOTIFICATIONS_EMPTY_SUBTITLE))
                } else {
                    self.tableView.restore()
                }
            }
        }
    }

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let userByTag = mentions[sender.view!.tag].post.author
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
        let selectedPost = mentions[tag]
        VotePost.default.vote(post: selectedPost.post, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [unowned self] in
                mentions[tag].post.voted = $0.status
                mentions[tag].post.score = $0.score
                // applyChanges()
                tableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .automatic)
            }.store(in: &subscriptions)
    }

    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id

        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = mentions[indexPath.row].post.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return mentions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView
        let post = mentions[indexPath.row]

        cell.delegate = self
        cell.indexPath = indexPath
        cell.post = post.post

        if !post.read {
            let unreadIndicator = UIView()
            unreadIndicator.backgroundColor = .systemBlue
            unreadIndicator.layer.cornerRadius = 10
            cell.addSubview(unreadIndicator)
            unreadIndicator.snp.makeConstraints { make in
                make.top.equalTo(cell.snp.top).offset(8)
                make.width.equalTo(20)
                make.height.equalTo(20)
                make.trailing.equalTo(cell.snp.trailing).offset(-8)
            }
        }

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

extension MentionsViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
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
                        self.loadMentions()
                    }.store(in: &subscriptions)
            }
        }
    }
}

#if targetEnvironment(macCatalyst)
    extension MentionsViewController: NSToolbarDelegate {
        func toolbar(_: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar _: Bool) -> NSToolbarItem? {
            if itemIdentifier == NSToolbarItem.Identifier("reloadData") {
                let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("reloadData"), barButtonItem: UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(loadMentions)))

                return item
            }
            return nil
        }

        func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [NSToolbarItem.Identifier("reloadData"), NSToolbarItem.Identifier.flexibleSpace]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return toolbarDefaultItemIdentifiers(toolbar)
        }
    }
#endif

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 25.07.20.
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

class BookmarksViewController: UIViewController {
    var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    var loadingHud: JGProgressHUD!
    private var subscriptions = Set<AnyCancellable>()
    var verificationString = ""
    var toolbarDelegate = ToolbarDelegate()
    private var navigateBackSubscriber: AnyCancellable?
    private var deleteSubscriber: AnyCancellable?

    var bookmarks = [AdvancedBookmark]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = SLocale(.BOOKMARKS)
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

        refreshControl.addTarget(self, action: #selector(loadBookmarks), for: .valueChanged)
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
                        collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.bookmarks.rawValue), animated: true, scrollPosition: .top)
                    }
                }
            }
        }
    }

    @objc func deleteAllConfirmation() {
        EZAlertController.alert(SLocale(.DELETE_ALL_BOOKMARKS), message: SLocale(.DELETE_ALL_BOOKMARKS_CONFIRMATION), actions: [
            UIAlertAction(title: SLocale(.CANCEL), style: .cancel, handler: { _ in
                //
			}),

            UIAlertAction(title: SLocale(.DELETE_ACTION), style: .destructive, handler: { _ in
                UserDefaults.standard.setStructArray([Bookmark](), forKey: "savedBookmarks")
                SPAlert.present(title: SLocale(.DELETED_ACTION), preset: .done)
                self.loadBookmarks(loadingIndicator: false)
			}),
        ])
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    override func viewWillDisappear(_: Bool) {
        navigateBackSubscriber?.cancel()
        deleteSubscriber?.cancel()
    }

    override func viewWillAppear(_: Bool) {
        setSidebar()

        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteAllConfirmation))

        let notificationCenter = NotificationCenter.default
        navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.navigateBack()
			})

        deleteSubscriber = notificationCenter.publisher(for: .delete)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.deleteAllConfirmation()
			})
    }

    override func viewDidAppear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "bookmarks")
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

        loadBookmarks()
    }

    @objc func loadBookmarks(loadingIndicator: Bool = true) {
        if loadingIndicator {
            loadingHud.show(in: view)
        }

        bookmarks.removeAll()

        DispatchQueue.global(qos: .utility).async { [self] in

            let myGroup = DispatchGroup()

            var savedBookmarks = UserDefaults.standard.structArrayData(Bookmark.self, forKey: "savedBookmarks")
            for i in savedBookmarks {
                myGroup.enter()
                AllesAPI.default.loadPost(id: i.id)
                    .receive(on: RunLoop.main)
                    .sink {
                        switch $0 {
                        case let .failure(err):
                            if err.error == .missingResource {
                                savedBookmarks.remove(at: savedBookmarks.firstIndex(of: i)!)
                                UserDefaults.standard.setStructArray(savedBookmarks, forKey: "savedBookmarks")
                            } else {
                                AllesAPI.default.errorHandling(error: err, caller: self.view)
                            }
                            myGroup.leave()

                        default: break
                        }
                    }
                receiveValue: { post in
                    self.bookmarks.append(AdvancedBookmark(bookmark: i, post: post))
                    myGroup.leave()
                }
                .store(in: &subscriptions)
            }

            myGroup.notify(queue: .main) {
                DispatchQueue.main.async { [self] in
                    bookmarks.sort { $0.bookmark.added.compare($1.bookmark.added) == .orderedDescending }
                    loadingHud.dismiss()
                    refreshControl.endRefreshing()
                    applyChanges()
                    verificationString = randomString(length: 30)
                    loadImages()
                }
            }
        }
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.global(qos: .background).async { [self] in
            let dispatchGroup = DispatchGroup()
            for (index, post) in bookmarks.enumerated() {
                dispatchGroup.enter()
                if index <= bookmarks.count - 1 {
                    if veri != verificationString { return }
                    bookmarks[index].post.author?.image = ImageLoader.loadImageFromInternet(url: post.post.author!.imgURL!)
                    if veri != verificationString { return }
                    if let mentionedPost = post.post.mentionedPost {
                        bookmarks[index].post.mentionedPost?.author?.image = ImageLoader.loadImageFromInternet(url: (mentionedPost.author?.imgURL)!)
                    }
                    if let url = post.post.imageURL {
                        bookmarks[index].post.image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        bookmarks[index].post.image = UIImage()
                    }
                    if index < 5 {
                        if veri != verificationString { return }
                        applyChanges()
                    }

                    dispatchGroup.leave()
                }
            }
            applyChanges()
        }
    }

    func applyChanges(_: Bool = true) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.bookmarks.isEmpty {
                self.tableView.setEmptyMessage(message: SLocale(.BOOKMARKS_EMPTY_TITLE), subtitle: SLocale(.BOOKMARKS_EMPTY_SUBTITLE))
            } else {
                self.tableView.restore()
            }
        }
    }

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let userByTag = bookmarks[sender.view!.tag].post.author
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
        let selectedPost = bookmarks[tag]
        VotePost.default.vote(post: selectedPost.post, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [unowned self] in
                bookmarks[tag].post.voted = $0.status
                bookmarks[tag].post.score = $0.score
                applyChanges()
            }.store(in: &subscriptions)
    }
}

enum BookmarkSection {
    case main
}

extension BookmarksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = bookmarks[indexPath.row]
        let detailVC = PostDetailViewController()
        detailVC.selectedPost = post.post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

        cell.delegate = self
        cell.indexPath = indexPath
        cell.post = bookmarks[indexPath.row].post

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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            bookmarks.remove(at: indexPath.row)
            let mappedBookmakrs = bookmarks.map { $0.bookmark }
            UserDefaults.standard.setStructArray(mappedBookmakrs, forKey: "savedBookmarks")
            SPAlert.present(title: SLocale(.DELETED_ACTION), preset: .done)
            tableView.beginUpdates()
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            tableView.endUpdates()
            loadBookmarks(loadingIndicator: false)
        }
    }
}

extension BookmarksViewController: PostCellViewDelegate {
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
            loadBookmarks()
        case .remove:
            var currentBookmarks = UserDefaults.standard.structArrayData(Bookmark.self, forKey: "savedBookmarks")
            if let index = currentBookmarks.firstIndex(where: { $0.id == id }) {
                currentBookmarks.remove(at: index)
                UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
                SPAlert.present(title: SLocale(.REMOVED_ACTION), preset: .done)
                loadBookmarks()
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
                    self.loadBookmarks()
                }.store(in: &subscriptions)
        }
    }
}

extension BookmarksViewController: PostCreateDelegate {
    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

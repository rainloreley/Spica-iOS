//
//  MentionsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Combine
import JGProgressHUD
import Lightbox
import SPAlert
import UIKit

class MentionsViewController: UIViewController, PostCreateDelegate {
    var tableView: UITableView!
	var toolbarDelegate = ToolbarDelegate()

    var mentions = [Post]() {
        didSet { applyChanges() }
    }

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()

    var verificationString = ""

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = SLocale(.NOTIFICATIONS)
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }

        // refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    // MARK: - Datasource

    typealias DataSource = UITableViewDiffableDataSource<Section, Post>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Post>

    private lazy var dataSource = makeDataSource()

    enum Section {
        case main
    }

    func makeDataSource() -> DataSource {
        let source = DataSource(tableView: tableView) { [self] (tableView, indexPath, post) -> UITableViewCell? in
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
        source.defaultRowAnimation = .fade
        return source
    }

    func applyChanges(_ animated: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(mentions, toSection: .main)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
			if self.mentions.isEmpty {
				self.tableView.setEmptyMessage(message: SLocale(.NOTIFICATIONS_EMPTY_TITLE), subtitle: SLocale(.NOTIFICATIONS_EMPTY_SUBTITLE))
			}
			else {
				self.tableView.restore()
			}
        }
    }

    func setSidebar() {
        if #available(iOS 14.0, *) {
            if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                if let sidebar = globalSideBarController {
                    if let collectionView = sidebar.collectionView {
                        collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.mentions.rawValue), animated: true, scrollPosition: .top)
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSidebar()

        navigationController?.navigationBar.prefersLargeTitles = true
		
		
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		
		#if targetEnvironment(macCatalyst)
		
			let toolbar = NSToolbar(identifier: "mentions")
			toolbar.delegate = toolbarDelegate
			toolbar.displayMode = .iconOnly
		
			if let titlebar = view.window!.windowScene!.titlebar {
				titlebar.toolbar = toolbar
				titlebar.toolbarStyle = .automatic
			}
	
			navigationController?.setNavigationBarHidden(true, animated: animated)
			navigationController?.setToolbarHidden(true, animated: animated)
		#endif
		
        setSidebar()
        /* #if targetEnvironment(macCatalyst)
             let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
             if let titleBar = sceneDelegate.window?.windowScene?.titlebar {
                 let toolBar = NSToolbar(identifier: "mentionsToolbar")
                 toolBar.delegate = self
                 titleBar.toolbar = toolBar
             }
         #endif */
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
            } receiveValue: { [unowned self] in
                self.mentions = $0
                self.refreshControl.endRefreshing()
                self.loadingHud.dismiss()
                self.verificationString = randomString(length: 30)
                self.loadImages()
            }.store(in: &subscriptions)
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.global(qos: .background).async { [self] in
            let dispatchGroup = DispatchGroup()
            for (index, post) in mentions.enumerated() {
                if veri != verificationString { return }
                dispatchGroup.enter()
                if index <= mentions.count - 1 {
                    if let author = mentions[index].author {
                        if veri != verificationString { return }
                        mentions[index].author?.image = ImageLoader.loadImageFromInternet(url: author.imageURL)
                    }

                    // applyChanges()
                    if let url = post.imageURL {
                        if veri != verificationString { return }
                        mentions[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        mentions[index].image = UIImage()
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

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let userByTag = mentions[sender.view!.tag].author
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
        VotePost.default.vote(post: selectedPost, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [unowned self] in
                mentions[tag].voteStatus = $0.status
                mentions[tag].score = $0.score
                applyChanges()
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
        detailVC.selectedPostID = mentions[indexPath.row].id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
    
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
			}
			else {
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
            // we got back an error!
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
                        self.loadMentions()
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
        let user = User(id: username, username: username, displayName: username, nickname: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
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

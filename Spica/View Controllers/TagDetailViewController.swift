//
//  TagDefailViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 22.07.20.
//

import Combine
import JGProgressHUD
import Lightbox
import SPAlert
import UIKit

class TagDetailViewController: UIViewController {
    typealias DataSource = UITableViewDiffableDataSource<Section, Post>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Post>

    var toolbarDelegate = ToolbarDelegate()
    var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    var loadingHud: JGProgressHUD!
    private var navigateBackSubscriber: AnyCancellable?

    var tag: Tag! {
        didSet {
            DispatchQueue.main.async {
                self.navigationItem.title = "#\(self.tag.name)"
            }
        }
    }

    private var subscriptions = Set<AnyCancellable>()
    private lazy var dataSource = makeDataSource()

    var verificationString = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "#\(tag.name)"

        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

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
        refreshControl.addTarget(self, action: #selector(loadTag), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewWillAppear(_: Bool) {
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

    override func viewWillDisappear(_: Bool) {
        navigateBackSubscriber?.cancel()
    }

    @objc func loadTag() {
        loadingHud.show(in: view)
        verificationString = ""
        AllesAPI.loadTag(tag: tag.name)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { tag in
                self.tag = tag
                self.applyChanges()
                self.refreshControl.endRefreshing()
                self.loadingHud.dismiss()
                self.verificationString = randomString(length: 30)
                self.loadImages()
            }
            .store(in: &subscriptions)
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.global(qos: .background).async { [self] in
            let dispatchGroup = DispatchGroup()
            for (index, post) in tag.posts.enumerated() {
                dispatchGroup.enter()
                if index <= tag.posts.count - 1 {
                    if veri != verificationString { return }
                    tag.posts[index].author?.image = ImageLoader.loadImageFromInternet(url: post.author!.imageURL)
                    // applyChanges()
                    if veri != verificationString { return }
                    if let url = post.imageURL {
                        tag.posts[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        tag.posts[index].image = UIImage()
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

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "tagdetail")
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

        if tag != nil {
            loadTag()
        }
    }

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let userByTag = tag.posts[sender.view!.tag].author
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
        let selectedPost = self.tag.posts[tag]
        VotePost.default.vote(post: selectedPost, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [unowned self] in
                self.tag.posts[tag].voteStatus = $0.status
                self.tag.posts[tag].score = $0.score
                applyChanges()
            }.store(in: &subscriptions)
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
        snapshot.appendItems(tag.posts, toSection: .main)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }

    enum Section: Hashable {
        case main
    }
}

extension TagDetailViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let post = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailVC = PostDetailViewController()
        detailVC.selectedPost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension TagDetailViewController: PostCreateDelegate {
    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension TagDetailViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
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
                    self.loadTag()
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

    func selectedUser(username: String, indexPath _: IndexPath) {
        let user = User(id: username, username: username, displayName: username, nickname: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

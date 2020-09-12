//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 01.07.20.
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

class PostDetailViewController: UIViewController, PostCreateDelegate {
    var selectedPostID: String!
    var toolbarDelegate = ToolbarDelegate()
    private var navigateBackSubscriber: AnyCancellable?
    var selectedPost: Post! {
        didSet {
            selectedPostID = selectedPost.id
        }
    }

    var mainPost: Post!

    var tableView: UITableView!

    var postAncestors = [Post]()
    var postReplies = [Post]()

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()
    var verificationString = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = SLocale(.POST_NOUN)
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(ReplyButtonCell.self, forCellReuseIdentifier: "replyButtonCell")
        tableView.register(AncestorPostDividerCell.self, forCellReuseIdentifier: "dividerCell")
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }

        refreshControl.addTarget(self, action: #selector(loadPostDetail), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewWillDisappear(_: Bool) {
        navigateBackSubscriber?.cancel()
    }

    override func viewWillAppear(_: Bool) {
        let notificationCenter = NotificationCenter.default
        navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.navigateBack()
			})

        navigationController?.navigationBar.prefersLargeTitles = false
        if selectedPost != nil {
            postAncestors = [selectedPost]
            tableView.reloadData()
        }
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "detail")
            toolbarDelegate.navStack = (navigationController?.viewControllers)!
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = toolbar
                titlebar.toolbarStyle = .automatic
                titlebar.titleVisibility = .visible
            }

            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
        #endif

        loadPostDetail()
    }

    @objc func loadPostDetail() {
        verificationString = ""

        if postAncestors.isEmpty || postReplies.isEmpty {
            DispatchQueue.main.async { [self] in
                loadingHud.show(in: view)
            }
        }

        AllesAPI.default.loadPostDetail(id: selectedPostID)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):

                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: {
                self.configure(with: $0)
            }.store(in: &subscriptions)
    }

    func loadImages() {
        let veri = verificationString
        DispatchQueue.global(qos: .utility).async { [self] in
            let dispatchGroup = DispatchGroup()

            for (index, post) in self.postAncestors.enumerated() {
                dispatchGroup.enter()
                if veri != verificationString { return }
                self.postAncestors[index].author?.image = ImageLoader.loadImageFromInternet(url: post.author!.imgURL!)
                if veri != verificationString { return }
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: 2 * index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }
                if let mentionedPost = post.mentionedPost {
                    self.postAncestors[index].mentionedPost?.author?.image = ImageLoader.loadImageFromInternet(url: (mentionedPost.author?.imgURL)!)
                }
                if veri != verificationString { return }
                if let url = post.imageURL {
                    self.postAncestors[index].image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    self.postAncestors[index].image = UIImage()
                }
                if veri != verificationString { return }
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: 2 * index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }

                dispatchGroup.leave()
            }

            for (index, post) in self.postReplies.enumerated() {
                dispatchGroup.enter()
                if veri != verificationString { return }
                self.postReplies[index].author?.image = ImageLoader.loadImageFromInternet(url: post.author!.imgURL!)
                if veri != verificationString { return }
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 2)], with: .automatic)
                    self.tableView.endUpdates()
                }
                if veri != verificationString { return }
                if let mentionedPost = post.mentionedPost {
                    self.postReplies[index].mentionedPost?.author?.image = ImageLoader.loadImageFromInternet(url: (mentionedPost.author?.imgURL)!)
                }
                if let url = post.imageURL {
                    self.postReplies[index].image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    self.postReplies[index].image = UIImage()
                }
                if veri != verificationString { return }
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 2)], with: .automatic)
                    self.tableView.endUpdates()
                }

                dispatchGroup.leave()
            }
        }
    }

    func configure(with postDetail: PostDetail?) {
        guard let postDetail = postDetail else { return }
        mainPost = postDetail.post
        postAncestors = postDetail.ancestors
        postAncestors.append(postDetail.post)
        postReplies = postDetail.replies
        tableView.reloadData()
        refreshControl.endRefreshing()
        loadingHud.dismiss()
        if let index = postAncestors.firstIndex(where: { $0.id == mainPost.id }) {
            tableView.scrollToRow(at: IndexPath(row: 2 * index, section: 0), at: .middle, animated: false)
        }
        verificationString = randomString(length: 30)
        loadImages()
    }

    @objc func openUserProfile(_ sender: UITapGestureRecognizer) {
        let newTag = String(sender.view!.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]
        let section = Int("\(sectionID)")!
        let row = Int(rowID)!

        let userByTag: User!
        if section == 0 {
            let count = Array(0 ... row).filter { !$0.isMultiple(of: 2) }.count

            userByTag = postAncestors[row - count].author
        } else {
            userByTag = postReplies[row].author
        }
        let vc = UserProfileViewController()
        vc.user = userByTag
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func upvotePost(_ sender: UIButton) {
        let newTag = String(sender.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let count = Array(0 ... Int(rowID)!).filter { !$0.isMultiple(of: 2) }.count
        let row = section == 0 ? Int(rowID)! - count : Int(rowID)!
        vote(section: section, tag: row, updateRow: section == 0 ? Int(rowID)! : row, vote: .upvote)
    }

    @objc func downvotePost(_ sender: UIButton) {
        let newTag = String(sender.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let count = Array(0 ... Int(rowID)!).filter { !$0.isMultiple(of: 2) }.count
        let row = section == 0 ? Int(rowID)! - count : Int(rowID)!
        vote(section: section, tag: row, updateRow: section == 0 ? Int(rowID)! : row, vote: .downvote)
    }

    func vote(section: Int, tag: Int, updateRow: Int, vote: VoteType) {
        let selectedPost = section == 0 ? postAncestors[tag] : postReplies[tag]
        VotePost.default.vote(post: selectedPost, vote: vote)
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
                if section == 0 {
                    postAncestors[tag].voted = $0.status
                    postAncestors[tag].score = $0.score
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: updateRow, section: section)], with: .automatic)
                    tableView.endUpdates()
                } else {
                    postReplies[tag].voted = $0.status
                    postReplies[tag].score = $0.score
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: updateRow, section: section)], with: .automatic)
                    tableView.endUpdates()
                }

            }.store(in: &subscriptions)
    }

    func didSendPost(sentPost: SentPost) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = sentPost.id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc func openReplyView(_: UIButton) {
        if mainPost != nil {
            let vc = PostCreateViewController()
            vc.type = .reply
            vc.delegate = self
            vc.parentID = mainPost.id
            present(UINavigationController(rootViewController: vc), animated: true)
        }
    }
}

extension PostDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return postAncestors.count + postAncestors.count - 1
        } else if section == 1 {
            return 1
        } else {
            return postReplies.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row % 2 == 0 {
                let count = Array(0 ... indexPath.row).filter { !$0.isMultiple(of: 2) }.count
                let post = postAncestors[indexPath.row - count]

                let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

                cell.layer.cornerRadius = 50.0

                cell.delegate = self
                cell.indexPath = indexPath
                cell.post = post

                let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
                cell.pfpImageView.tag = Int("9\(indexPath.section)\(indexPath.row)")!
                cell.pfpImageView.isUserInteractionEnabled = true
                cell.pfpImageView.addGestureRecognizer(tap)

                cell.upvoteButton.tag = Int("9\(indexPath.section)\(indexPath.row)")!
                cell.upvoteButton.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

                cell.downvoteButton.tag = Int("9\(indexPath.section)\(indexPath.row)")!
                cell.downvoteButton.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "dividerCell", for: indexPath) as! AncestorPostDividerCell
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                return cell
            }

        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "replyButtonCell", for: indexPath) as! ReplyButtonCell

            cell.replyBtn.addTarget(self, action: #selector(openReplyView(_:)), for: .touchUpInside)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        } else {
            let post = postReplies[indexPath.row]

            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

            cell.delegate = self
            cell.indexPath = indexPath
            cell.post = post

            let tap = UITapGestureRecognizer(target: self, action: #selector(openUserProfile(_:)))
            cell.pfpImageView.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.pfpImageView.isUserInteractionEnabled = true
            cell.pfpImageView.addGestureRecognizer(tap)

            cell.upvoteButton.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.upvoteButton.addTarget(self, action: #selector(upvotePost(_:)), for: .touchUpInside)

            cell.downvoteButton.tag = Int("9\(indexPath.section)\(indexPath.row)")!
            cell.downvoteButton.addTarget(self, action: #selector(downvotePost(_:)), for: .touchUpInside)

            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 1 {
            let detailVC = PostDetailViewController()
            detailVC.hidesBottomBarWhenPushed = true
            if indexPath.section == 0, indexPath.row % 2 == 0 {
                let detailVC = PostDetailViewController()
                let count = Array(0 ... indexPath.row).filter { !$0.isMultiple(of: 2) }.count
                detailVC.selectedPostID = postAncestors[indexPath.row - count].id
                navigationController?.pushViewController(detailVC, animated: true)
            } else if indexPath.section == 2 {
                detailVC.selectedPostID = postReplies[indexPath.row].id
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
}

extension PostDetailViewController: PostCellViewDelegate, UIImagePickerControllerDelegate {
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
                        self.navigationController?.popViewController(animated: true)
                        SPAlert.present(title: SLocale(.DELETED_ACTION), preset: .done)
                    }.store(in: &subscriptions)
            }
        }
    }
}

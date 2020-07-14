//
//  PostDetailViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
//

import Combine
import JGProgressHUD
import SPAlert
import UIKit

class PostDetailViewController: UIViewController, PostCreateDelegate {
    var selectedPostID: String!
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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Post"
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(ReplyButtonCell.self, forCellReuseIdentifier: "replyButtonCell")
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }

        // refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadPostDetail), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
        loadingHud.interactionType = .blockNoTouches

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
        if selectedPost != nil {
            postAncestors = [selectedPost]
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_: Bool) {
        loadPostDetail()
    }

    @objc func loadPostDetail() {
        if postAncestors.isEmpty || postReplies.isEmpty {
            DispatchQueue.main.async { [self] in
                loadingHud.show(in: view)
            }
        }

        AllesAPI.loadPostDetail(id: selectedPostID)
            .receive(on: RunLoop.main)
            .sink {
                // guard let self = self else { return }
                switch $0 {
                case let .failure(err):

                    EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                        self.refreshControl.endRefreshing()
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
            } receiveValue: {
                self.configure(with: $0)
            }.store(in: &subscriptions)
    }

    func loadImages() {
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()

            for (index, post) in self.postAncestors.enumerated() {
                dispatchGroup.enter()

                self.postAncestors[index].author.image = ImageLoader.loadImageFromInternet(url: post.author.imageURL)

                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }

                if let url = post.imageURL {
                    self.postAncestors[index].image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    self.postAncestors[index].image = UIImage()
                }

                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                }

                dispatchGroup.leave()
            }

            for (index, post) in self.postReplies.enumerated() {
                dispatchGroup.enter()

                self.postReplies[index].author.image = ImageLoader.loadImageFromInternet(url: post.author.imageURL)

                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 2)], with: .automatic)
                    self.tableView.endUpdates()
                }

                if let url = post.imageURL {
                    self.postReplies[index].image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    self.postReplies[index].image = UIImage()
                }

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
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
        }
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
            userByTag = postAncestors[row].author
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
        let row = Int(rowID)!
        vote(section: section, tag: row, vote: .upvote)
    }

    @objc func downvotePost(_ sender: UIButton) {
        let newTag = String(sender.tag)
        let sectionID = newTag[newTag.index(newTag.startIndex, offsetBy: 1)]
        let rowID = newTag.components(separatedBy: "9\(sectionID)")[1]

        let section = Int("\(sectionID)")!
        let row = Int(rowID)!
        vote(section: section, tag: row, vote: .downvote)
    }

    func vote(section: Int, tag: Int, vote: VoteType) {
        let selectedPost = section == 0 ? postAncestors[tag] : postReplies[tag]
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
                if section == 0 {
                    postAncestors[tag].voteStatus = $0.status
                    postAncestors[tag].score = $0.score
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: tag, section: section)], with: .automatic)
                    tableView.endUpdates()
                } else {
                    postReplies[tag].voteStatus = $0.status
                    postReplies[tag].score = $0.score
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: tag, section: section)], with: .automatic)
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
            return postAncestors.count
        } else if section == 1 {
            return 1
        } else {
            return postReplies.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let post = postAncestors[indexPath.row]

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

        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "replyButtonCell", for: indexPath) as! ReplyButtonCell

            cell.replyBtn.addTarget(self, action: #selector(openReplyView(_:)), for: .touchUpInside)
            cell.backgroundColor = .clear
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
            if indexPath.section == 0 {
                detailVC.selectedPostID = postAncestors[indexPath.row].id
            } else if indexPath.section == 2 {
                detailVC.selectedPostID = postReplies[indexPath.row].id
            }

            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension PostDetailViewController: PostCellViewDelegate {
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
                        self.loadPostDetail()
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

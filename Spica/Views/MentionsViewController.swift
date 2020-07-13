//
//  MentionsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import JGProgressHUD
import SPAlert
import UIKit

class MentionsViewController: UIViewController, PostCreateDelegate {
    var tableView: UITableView!

    var mentions = [Post]() {
        didSet { applyChanges() }
    }

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Notifications"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        view.addSubview(tableView)

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(loadMentions), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
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
        source.defaultRowAnimation = .top
        return source
    }
    
    func applyChanges(_ animated: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(mentions, toSection: .main)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadMentions()
    }

    @objc func loadMentions() {
        if mentions.isEmpty {
            loadingHud.show(in: view)
        }
        AllesAPI.default.loadMentions { result in
            switch result {
            case let .success(newPosts):
                DispatchQueue.main.async {
                    self.mentions = newPosts
                    self.refreshControl.endRefreshing()
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

            for (index, post) in self.mentions.enumerated() {
                dispatchGroup.enter()

                self.mentions[index].author.image = ImageLoader.loadImageFromInternet(url: post.author.imageURL)

                self.applyChanges()

                if let url = post.imageURL {
                    self.mentions[index].image = ImageLoader.loadImageFromInternet(url: url)
                } else {
                    self.mentions[index].image = UIImage()
                }

                self.applyChanges()
                dispatchGroup.leave()
            }
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
        let selectedPost = mentions[sender.tag]
        var selectedVoteStatus = 0
        if selectedPost.voteStatus == 1 {
            selectedVoteStatus = 0
        } else {
            selectedVoteStatus = 1
        }

        AllesAPI.default.votePost(post: selectedPost, value: selectedVoteStatus) { result in
            switch result {
            case .success:
                DispatchQueue.main.async { [self] in
                    if mentions[sender.tag].voteStatus == -1 {
                        mentions[sender.tag].score += 2
                    } else if selectedVoteStatus == 0 {
                        mentions[sender.tag].score -= 1
                    } else {
                        mentions[sender.tag].score += 1
                    }
                    mentions[sender.tag].voteStatus = selectedVoteStatus

                    applyChanges()
                }

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
        let selectedPost = mentions[sender.tag]
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
                    if self.mentions[sender.tag].voteStatus == 1 {
                        self.mentions[sender.tag].score -= 2
                    } else if selectedVoteStatus == 0 {
                        self.mentions[sender.tag].score += 1
                    } else {
                        self.mentions[sender.tag].score -= 1
                    }
                    self.mentions[sender.tag].voteStatus = selectedVoteStatus

                    self.applyChanges()
                }

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

extension MentionsViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PostDetailViewController()
        detailVC.selectedPostID = mentions[indexPath.row].id
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension MentionsViewController: PostCellViewDelegate {
    func repost(id _: String, username _: String) {
        //
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
        EZAlertController.alert("Delete post", message: "Are you sure you want to delete this post?", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { _, int in
            if int == 1 {
                AllesAPI.default.deletePost(id: id) { result in
                    switch result {
                    case .success:
                        self.loadMentions()
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
        let user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

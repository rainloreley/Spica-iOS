//
//  ViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Combine
import JGProgressHUD
import SnapKit
import SPAlert
import SwiftKeychainWrapper
import UIKit

class ViewController: UIViewController, PostCreateDelegate, UITextViewDelegate {
    var tableView: UITableView!
    var createPostBtn: UIButton!
    var posts = [Post]() {
        didSet { applyChanges() }
    }

    var refreshControl = UIRefreshControl()

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        let accountBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(openOwnProfileView))

        let createPostBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openPostCreateView))

        navigationItem.rightBarButtonItems = [createPostBarButtonItem, accountBarButtonItem]

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))

        tableView = UITableView(frame: view.bounds, style: .plain)
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
        refreshControl.addTarget(self, action: #selector(loadFeed), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading"
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

        view.addSubview(createPostBtn)

        createPostBtn.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.bottom.equalTo(view.snp.bottom).offset(-100)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
        }
    }

    // MARK: - Datasource

    typealias DataSource = UITableViewDiffableDataSource<Section, Post>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Post>

    enum Section: Hashable {
        case main
    }

    private lazy var dataSource = makeDataSource()

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
        snapshot.appendItems(posts, toSection: .main)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: animated)
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
        let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
        vc.user = User(id: "", username: username!, displayName: username!, imageURL: URL(string: "https://avatar.alles.cx/u/\(username!)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username!)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func openPostCreateView() {
        let vc = PostCreateViewController()
        vc.type = .post
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadFeed()
    }

    @objc func loadFeed() {
        if posts.isEmpty { loadingHud.show(in: view) }
        AllesAPI.loadFeed()
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { [self] _, _ in
                        refreshControl.endRefreshing()
                        loadingHud.dismiss()
                        if err.action != nil, err.actionParameter != nil {
                            if err.action == AllesAPIErrorAction.navigate, err.actionParameter == "login" {
                                let mySceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
                                mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                mySceneDelegate.window?.makeKeyAndVisible()
                            }
                        }
                    }
                default: break
                }
            } receiveValue: { [unowned self] in
                posts = $0
                refreshControl.endRefreshing()
                loadingHud.dismiss()
                loadImages()
            }.store(in: &subscriptions)
    }

    func loadImages() {
        DispatchQueue.global(qos: .utility).async { [self] in
            let dispatchGroup = DispatchGroup()
            for (index, post) in posts.enumerated() {
                dispatchGroup.enter()
                if index <= posts.count - 1 {
                    posts[index].author.image = ImageLoader.loadImageFromInternet(url: post.author.imageURL)
                    applyChanges()
                    if let url = post.imageURL {
                        posts[index].image = ImageLoader.loadImageFromInternet(url: url)
                    } else {
                        posts[index].image = UIImage()
                    }
                    applyChanges()
                    dispatchGroup.leave()
                }
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
					case .failure(let err):
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
				posts[tag].voteStatus = $0.status
				posts[tag].score = $0.score
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

extension ViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let post = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailVC = PostDetailViewController()
        detailVC.selectedPost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension ViewController: MainSettingsDelegate {
    func clickedMore(username: String) {
        let vc = UserProfileViewController()
        vc.user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle")!, isFollowing: false, followsMe: false, about: "", isOnline: false)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController: PostCellViewDelegate {
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
        EZAlertController.alert("Delete post", message: "Are you sure you want to delete this post?", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, index in
            guard index == 1 else { return }

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

    func selectedUser(username: String, indexPath _: IndexPath) {
        let user = User(id: username, username: username, displayName: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
        let vc = UserProfileViewController()
        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

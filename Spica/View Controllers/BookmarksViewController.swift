//
//  BookmarksViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 25.07.20.
//

import UIKit
import JGProgressHUD
import Combine
import Lightbox

class BookmarksViewController: UIViewController {
	
	var tableView: UITableView!
	var refreshControl = UIRefreshControl()
	var loadingHud: JGProgressHUD!
	private var subscriptions = Set<AnyCancellable>()
	
	var bookmarks = [Post]()

    override func viewDidLoad() {
        super.viewDidLoad()

		view.backgroundColor = .systemBackground
		navigationItem.title = "Bookmarks"
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
		refreshControl.addTarget(self, action: #selector(loadBookmarks), for: .valueChanged)
		tableView.addSubview(refreshControl)

		loadingHud = JGProgressHUD(style: .dark)
		loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
		loadingHud.interactionType = .blockNoTouches
    }
	
	@objc func loadBookmarks() {
		let savedBookmarks = UserDefaults.standard.array(forKey: "savedBookmarks") ?? []
		for i in savedBookmarks {
			
		}
	}
	
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
		snapshot.appendItems(bookmarks, toSection: .main)
		DispatchQueue.main.async {
			self.dataSource.apply(snapshot, animatingDifferences: animated)
		}
	}
	
	
	@objc func openUserProfile(_ sender: UITapGestureRecognizer) {
		let userByTag = bookmarks[sender.view!.tag].author
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
		VotePost.default.vote(post: selectedPost, vote: vote)
			.receive(on: RunLoop.main)
			.sink {
				switch $0 {
				case let .failure(err):

					AllesAPI.default.errorHandling(error: err, caller: self.view)
				default: break
				}
			} receiveValue: { [unowned self] in
				bookmarks[tag].voteStatus = $0.status
				bookmarks[tag].score = $0.score
				applyChanges()
			}.store(in: &subscriptions)
	}
}

extension BookmarksViewController: UITableViewDelegate {
	
}

extension BookmarksViewController: PostCellViewDelegate {
	func selectedUser(username: String, indexPath: IndexPath) {
		//
	}
	
	func selectedURL(url: String, indexPath: IndexPath) {
		//
	}
	
	func selectedPost(post: String, indexPath: IndexPath) {
		//
	}
	
	func selectedTag(tag: String, indexPath: IndexPath) {
		//
	}
	
	func copyPostID(id: String) {
		//
	}
	
	func deletePost(id: String) {
		//
	}
	
	func replyToPost(id: String) {
		//
	}
	
	func repost(id: String, username: String) {
		//
	}
	
	func clickedOnImage(controller: LightboxController) {
		//
	}
	
	func saveImage(image: UIImage?) {
		//
	}
	
	
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import SafariServices
import SPAlert
import UIKit

class BookmarksViewController: UITableViewController {
    var bookmarks = [Bookmark]()

    var loadingHud: JGProgressHUD!
	var imageReloadedCells = [String]()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Bookmarks"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteAllConfirmation))
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadBookmarks), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewDidAppear(_: Bool) {
        loadBookmarks()
    }

    @objc func deleteAllConfirmation() {
        EZAlertController.alert("Delete all bookmarks?", message: "Are you sure you want to delete all bookmarks?", actions: [
            UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                //
				}),

            UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                UserDefaults.standard.setStructArray([StoredBookmark](), forKey: "savedBookmarks")
                SPAlert.present(title: "Deleted!", preset: .done)
                self.loadBookmarks(showLoadingIndicator: false)
				}),
        ])
    }

    @objc func loadBookmarks(showLoadingIndicator: Bool = true) {
        if bookmarks.isEmpty, showLoadingIndicator { loadingHud.show(in: view) }
        let savedBookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")
        MicroAPI.default.loadBookmarks(savedBookmarks) { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(returnedBookmarks):
                DispatchQueue.main.async { [self] in
                    bookmarks = returnedBookmarks
                    bookmarks.sort { $0.storedbookmark.added.compare($1.storedbookmark.added) == .orderedDescending }
                    tableView.reloadData()
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()

                    if bookmarks.isEmpty {
                        tableView.setEmptyMessage(message: "No bookmarks", subtitle: "You can bookmark a post by long-pressing it")
                    } else {
                        tableView.restore()
                    }
                }
            }
        }
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return bookmarks.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView
		
		cell.indexPath = indexPath
		cell.delegate = self
        cell.post = bookmarks[indexPath.section].post

        return cell
    }
}

extension BookmarksViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension BookmarksViewController: PostCellDelegate {
	
	func reloadCell(_ at: IndexPath) {
		if !imageReloadedCells.contains(bookmarks[at.section].post.id) {
			imageReloadedCells.append(bookmarks[at.section].post.id)
			DispatchQueue.main.async {
				self.tableView.reloadRows(at: [at], with: .automatic)
			}
		}
	}
	
    func clickedLink(_ url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.delegate = self
        present(vc, animated: true)
    }

    func openPostView(_ type: PostType, preText: String?, preLink: String?, parentID: String?) {
        let vc = CreatePostViewController()
        vc.type = type
        vc.delegate = self
        vc.parentID = parentID
        vc.preText = preText ?? ""
        vc.preLink = preLink
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func reloadData() {
        loadBookmarks()
    }

    func clickedUser(user: User) {
        let detailVC = UserProfileViewController(style: .insetGrouped)
        detailVC.user = user
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func clickedImage(_ controller: ImageDetailViewController) {
        present(controller, animated: true, completion: nil)
    }
}

extension BookmarksViewController: CreatePostDelegate {
    func didSendPost(post: Post?) {
        if post != nil {
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.mainpost = post!
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension BookmarksViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = bookmarks[indexPath.section].post
        let detailVC = PostDetailViewController(style: .insetGrouped)
        detailVC.mainpost = post
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

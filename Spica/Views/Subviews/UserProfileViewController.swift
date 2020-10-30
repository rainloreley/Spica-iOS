//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
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
import SwiftKeychainWrapper
import UIKit

class UserProfileViewController: UITableViewController {
    var user: User = User()
    var userposts = [Post]()
    var userDataLoaded = false
    var imageReloadedCells = [String]()

    var loadingHud: JGProgressHUD!

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = user.name
        tableView.register(PostCellView.self, forCellReuseIdentifier: "postCell")
        tableView.register(UserHeaderViewCell.self, forCellReuseIdentifier: "headerCellUI")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadUser), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewDidAppear(_: Bool) {
        loadUser()
    }

    @objc func openUpdateStatusSheet() {
        let vc = CreatePostViewController()
        // vc.type = .status
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc func loadUser() {
        if userposts.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadUser(user.id, loadAdditionalInfo: true) { [self] result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(user):
                DispatchQueue.main.async {
                    self.user = user
                    navigationItem.title = user.name
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    let signedInUID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
                    if user.id == signedInUID {
                        KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.name")
                        KeychainWrapper.standard.set(user.tag, forKey: "dev.abmgrt.spica.user.tag")
                    }
                    loadUserPosts()
                }
            }
        }
    }

    func loadUserPosts() {
        MicroAPI.default.loadUserPosts(user.id) { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(userposts):
                DispatchQueue.main.async { [self] in
                    self.userposts = userposts
                    userDataLoaded = true
                    loadingHud.dismiss()
                    refreshControl?.endRefreshing()
                    tableView.reloadData()
                }
            }
        }
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return userposts.count + 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCellUI", for: indexPath) as! UserHeaderViewCell
            cell.selectionStyle = .none
            cell.headerController.user = user
            cell.headerController.userDataLoaded = userDataLoaded
            cell.headerController.delegate = self
            cell.headerController.getLoggedInUser()
            return cell
        } else {
            let post = userposts[indexPath.section - 1]

            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCellView

            cell.indexPath = indexPath
            cell.delegate = self
            cell.post = post

            return cell
        }
    }
}

extension UserProfileViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            let post = userposts[indexPath.section - 1]
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.mainpost = post
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension UserProfileViewController: UserHeaderDelegate {
	
	func clickedOnProfilePicture(_ image: UIImage) {
		let controller = ImageDetailViewController(images: [LightboxImage(image: image)], startIndex: 0)
		controller.dynamicBackground = true
		present(controller, animated: true, completion: nil)
	}
	
    func showError(title: String, message: String) {
        EZAlertController.alert(title, message: message)
    }

    func clickedOnFollowerCount() {
        let vc = FollowersFollowingViewController()
        vc.selectedIndex = 0
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func clickedOnFollowingCount() {
        let vc = FollowersFollowingViewController()
        vc.selectedIndex = 1
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UserProfileViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_: SFSafariViewController) {
        dismiss(animated: true)
    }
}

extension UserProfileViewController: PostCellDelegate {
    func reloadCell(_ at: IndexPath) {
        if !imageReloadedCells.contains(userposts[at.section - 1].id) {
            imageReloadedCells.append(userposts[at.section - 1].id)
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
        loadUser()
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

extension UserProfileViewController: CreatePostDelegate {
    func didSendPost(post: Post?) {
        if post != nil {
            let detailVC = PostDetailViewController(style: .insetGrouped)
            detailVC.mainpost = post!
            detailVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            loadUser()
        }
    }
}

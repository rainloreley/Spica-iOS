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
import SwiftUI
import UIKit
import Kingfisher

class UserProfileViewController: UITableViewController {
    var user: User = User()
    var userposts = [Post]()
    var userDataLoaded = false
    var imageReloadedCells = [String]()

    var loadingHud: JGProgressHUD!
    var postView: UIHostingController<CreatePostView>?

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
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(openNewPostView)), UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(openUserOptions(_:)))]

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewDidAppear(_: Bool) {
        loadUser()
    }
	
	@objc func showImagePicker(_ source: UIImagePickerController.SourceType) {
		let pickercontroller = UIImagePickerController()
		pickercontroller.sourceType = source
		//pickercontroller.allowsEditing = true
		pickercontroller.delegate = self
		present(pickercontroller, animated: true, completion: nil)
	}
	
	@objc func openNewPostView() {
		postView = UIHostingController(rootView: CreatePostView(type: .post, controller: CreatePostController(loadedDraftId: randomString(length: 30), delegate: self, preText: "@\(user.username ?? user.id)")))
		postView?.isModalInPresentation = true
		present(UINavigationController(rootViewController: postView!), animated: true)
	}

    @objc func openUserOptions(_ sender: UIBarButtonItem) {
        let userOptionsSheet = UIAlertController(title: "\(user.name)", message: nil, preferredStyle: .actionSheet)

        if let popoverController = userOptionsSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        let allesPeopleAction = UIAlertAction(title: "Open Alles People page", style: .default) { _ in
            let vc = SFSafariViewController(url: URL(string: "https://alles.cx/\(self.user.id)")!)
            vc.delegate = self
            self.present(vc, animated: true)
        }

        let copyIDAction = UIAlertAction(title: "Copy ID", style: .default) { _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = self.user.id
            SPAlert.present(title: "Copied", preset: .done)
        }
		

        let changeSubscriptionStatus = UIAlertAction(title: user.userSubscribedTo ? "Disable notifications" : "Enable notifications", style: .default) { [self] _ in
            SpicaPushAPI.default.changeUserSubscription(user.id, add: !user.userSubscribedTo) { result in
                switch result {
                case let .failure(err):
                    MicroAPI.default.errorHandling(error: err, caller: view)
                case .success:
                    user.userSubscribedTo.toggle()
                    SPAlert.present(title: "Changed notification status", preset: .done)
                    loadUser()
                }
            }
        }
		
		userOptionsSheet.addAction(allesPeopleAction)
		userOptionsSheet.addAction(copyIDAction)
		
		let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
		
		if user.id == signedInID {
			let changeProfilePictureAction = UIAlertAction(title: "Change profile picture", style: .default) { [self] (_) in
				
				updatePfpSourceSheet(sender)
			}
			
			userOptionsSheet.addAction(changeProfilePictureAction)
		}

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        if user.id != KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id"), userDataLoaded, user.spicaUserHasPushAccount {
            userOptionsSheet.addAction(changeSubscriptionStatus)
        }
        userOptionsSheet.addAction(cancelAction)

        present(userOptionsSheet, animated: true, completion: nil)
    }
	
	@objc func updatePfpSourceSheet(_ sender: UIBarButtonItem?) {
		let pfpSourceSheet = UIAlertController(title: "Source", message: "Please select a source", preferredStyle: .actionSheet)
		
		if let popoverController = pfpSourceSheet.popoverPresentationController, sender != nil {
			popoverController.barButtonItem = sender!
		}
		else if let popoverController = pfpSourceSheet.popoverPresentationController {
			popoverController.sourceView = view
			popoverController.sourceRect = view.bounds
		}
		
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			let camera = UIAlertAction(title: "Camera", style: .default) { (_) in
				self.showImagePicker(.camera)
			}
			pfpSourceSheet.addAction(camera)
		}
		
		let photoLibrary = UIAlertAction(title: "Library", style: .default) { (_) in
			self.showImagePicker(.photoLibrary)
		}
		pfpSourceSheet.addAction(photoLibrary)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		pfpSourceSheet.addAction(cancelAction)
		
		self.present(pfpSourceSheet, animated: true, completion: nil)
	}

    @objc func loadUser() {
        if userposts.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadUser(user.id, loadStatus: true, loadRing: true) { [self] result in
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

extension UserProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let image = info[.editedImage] as? UIImage {
			picker.dismiss(animated: true, completion: nil)
			uploadNewProfilePicture(image)
		}
		
		if let image = info[.originalImage] as? UIImage {
			picker.dismiss(animated: true, completion: nil)
			uploadNewProfilePicture(image)
		} else {
			picker.dismiss(animated: true, completion: nil)
		}
	}
	
	func uploadNewProfilePicture(_ image: UIImage) {
		MicroAPI.default.updateProfilePicture(image) { (result) in
			switch result {
				case .success:
					DispatchQueue.main.async {
						Kingfisher.ImageCache.default.clearCache {
							SPAlert.present(title: "Updated!", preset: .done)
							self.loadUser()
						}
					}
				case let .failure(err):
					DispatchQueue.main.async {
						MicroAPI.default.errorHandling(error: err, caller: self.view)
					}
					
			}
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
    func clickedOnProfilePicture(_ image: UIImage?) {
		let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
		
		if user.id == signedInID {
			updatePfpSourceSheet(nil)
		}
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
    func updatePost(_ post: Post, reload: Bool, at: IndexPath) {
        guard let postIndexInArray = userposts.firstIndex(where: { $0.id == post.id }) else { return }
        userposts[postIndexInArray] = post
        if reload {
            tableView.reloadRows(at: [at], with: .automatic)
        }
    }

    func deletedPost(_: Post) {
        loadUser()
    }

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
        postView = UIHostingController(rootView: CreatePostView(type: type, controller: .init(delegate: self, parentID: parentID, preText: preText ?? "", preLink: preLink ?? "")))
        postView?.isModalInPresentation = true
        present(UINavigationController(rootViewController: postView!), animated: true)
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
    func dismissView() {
        postView!.dismiss(animated: true, completion: nil)
    }

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

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Lightbox
import SPAlert
import SwiftKeychainWrapper
import UIKit

class UserProfileViewController: UITableViewController {
    var user: User = User()
    var userposts = [Post]()
    var userDataLoaded = false

    var loadingHud: JGProgressHUD!

    private var subscriptions = Set<AnyCancellable>()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = user.name
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "postCell")
        tableView.register(UserHeaderViewCell.self, forCellReuseIdentifier: "headerCellUI")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(loadUser), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches
    }

    override func viewDidAppear(_: Bool) {
        loadUser()
    }

    @objc func loadUser() {
        if userposts.isEmpty { loadingHud.show(in: view) }
        MicroAPI.default.loadUser(user.id)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [self] user in
                self.user = user
                navigationItem.title = user.name
                let signedInUID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
                if user.id == signedInUID {
                    KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.name")
                    KeychainWrapper.standard.set(user.tag, forKey: "dev.abmgrt.spica.user.tag")
                }
                loadUserPosts()
            }.store(in: &subscriptions)
    }

    func loadUserPosts() {
        MicroAPI.default.loadUserPosts(user.id)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                default: break
                }
            } receiveValue: { [self] userposts in
                self.userposts = userposts
                userDataLoaded = true
                loadingHud.dismiss()
                refreshControl?.endRefreshing()
                tableView.reloadData()
            }.store(in: &subscriptions)
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
            // cell.headerController.grow = imageAnimationAllowed
            return cell
        } else {
            let post = userposts[indexPath.section - 1]

            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! PostCell

            cell.post = post
            cell.delegate = self

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
    func showError(title: String, message: String) {
        EZAlertController.alert(title, message: message)
    }

    func clickedOnFollowerCount() {
        //
    }

    func clickedOnFollowingCount() {
        //
    }
}

extension UserProfileViewController: PostCellDelegate {
    func clickedUser(user: User) {
        let detailVC = UserProfileViewController(style: .insetGrouped)
        detailVC.user = user
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func clickedImage(controller: LightboxController) {
        present(controller, animated: true, completion: nil)
    }
}

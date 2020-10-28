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
import KingfisherSwiftUI
import SwiftUI
import UIKit

class FollowersFollowingViewController: UIViewController {
    var followers = [User]()
    var following = [User]()

    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!

    var refreshControl = UIRefreshControl()
    var loadingHud: JGProgressHUD!
    var selectedIndex = 0

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func updateTitle() {
        navigationItem.title = selectedIndex == 0 ? "Followers" : "Following"
    }

    override func viewDidAppear(_: Bool) {
        loadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()

        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        segmentedControl = UISegmentedControl(items: ["Followers", "Following"])
        segmentedControl.selectedSegmentIndex = selectedIndex
        segmentedControl.addTarget(self, action: #selector(loadData), for: .valueChanged)

        view.addSubview(segmentedControl)

        segmentedControl.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-8)
            make.leading.equalTo(view.snp.leading).offset(16)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
            make.height.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(segmentedControl.snp.top).offset(-8)
        }
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches

        // Do any additional setup after loading the view.
    }

    @objc func loadData() {
        selectedIndex = segmentedControl.selectedSegmentIndex
        updateTitle()
        selectedIndex == 0 ? loadFollowers() : loadFollowing()
    }

    func loadFollowers() {
        if followers.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadFollowers { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(users):
                DispatchQueue.main.async { [self] in
                    followers = users
                    followers.sort(by: { $0.name < $1.name })
                    tableView.reloadData()
                    refreshControl.endRefreshing()
                    loadingHud.dismiss()
                }
            }
        }
    }

    func loadFollowing() {
        if following.isEmpty { loadingHud.show(in: view) }

        MicroAPI.default.loadFollowing { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(users):
                DispatchQueue.main.async { [self] in
                    following = users
                    following.sort(by: { $0.name < $1.name })
                    tableView.reloadData()
                    refreshControl.endRefreshing()
                    loadingHud.dismiss()
                }
            }
        }
    }
}

extension FollowersFollowingViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return selectedIndex == 0 ? followers.count : following.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let user = selectedIndex == 0 ? followers[indexPath.section] : following[indexPath.section]

        let content = UIHostingController(rootView: UserCell(user: user)).view
        content?.backgroundColor = .secondarySystemGroupedBackground
        cell.contentView.addSubview(content!)
        content?.snp.makeConstraints { make in
            make.top.equalTo(cell.contentView.snp.top)
            make.leading.equalTo(cell.contentView.snp.leading)
            make.bottom.equalTo(cell.contentView.snp.bottom)
            make.trailing.equalTo(cell.contentView.snp.trailing)
        }
        return cell
    }
}

extension FollowersFollowingViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = segmentedControl.selectedSegmentIndex == 0 ? followers[indexPath.section] : following[indexPath.section]
        let vc = UserProfileViewController(style: .insetGrouped)

        vc.user = user
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

struct UserCell: View {
    var user: User!

    var body: some View {
        HStack {
            // Image(uiImage: follower.image ?? UIImage(systemName: "person.circle"))
            KFImage(user.profilePictureUrl)
                .resizable().frame(width: 40, height: 40, alignment: .leading).cornerRadius(20)
            VStack(alignment: .leading) {
                Text("\(user.name)").bold()
                Text("\(user.name)#\(user.tag)").foregroundColor(.secondary)
            }
            Spacer()
        }.padding()
    }
}

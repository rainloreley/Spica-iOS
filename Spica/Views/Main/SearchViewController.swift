//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import SwiftUI
import UIKit

class SearchViewController: UITableViewController {
    var users = [User]()
    var searchText = ""

    var loadingHud: JGProgressHUD!
    let searchBar = UISearchBar()
    private lazy var searchController = makeSearchController()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        searchText = ""
        searchBar.text = ""
        users.removeAll()
        tableView.reloadData()
        tableView.setEmptyMessage(message: "Search", subtitle: "Try searching for \"Archie Baer\"! His account should appear here")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Search"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(performSearch), for: .valueChanged)
        tableView.addSubview(refreshControl!)
        tableView.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockNoTouches

        /* searchBar.searchBarStyle = .prominent
         searchBar.placeholder = "Search for a name"
         searchBar.sizeToFit()
         searchBar.isTranslucent = false
         searchBar.backgroundImage = UIImage()
         searchBar.delegate = self

         navigationItem.titleView = searchBar */
        navigationItem.searchController = searchController
    }

    @objc func performSearch() {
        loadingHud.show(in: view)
        MicroAPI.default.searchUser(searchText) { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.loadingHud.dismiss()
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case let .success(receivedUsers):
                DispatchQueue.main.async { [self] in
                    users = receivedUsers
                    refreshControl!.endRefreshing()
                    loadingHud.dismiss()
                    tableView.reloadData()
                    if users.isEmpty {
                        tableView.setEmptyMessage(message: "No results", subtitle: "We didn't find a user called \(String("\"\(searchText)\""))... Remember that you need to search for the full name")
                    } else {
                        tableView.restore()
                    }
                }
            }
        }
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return users.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let content = UIHostingController(rootView: UserCell(user: users[indexPath.section])).view
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

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange text: String) {
        searchText = text
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        searchText = searchBar.text!
        performSearch()
    }
}

extension SearchViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = UserProfileViewController(style: .insetGrouped)
        detailVC.user = users[indexPath.section]
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension SearchViewController {
    private func makeSearchController() -> UISearchController {
        let controller = UISearchController()

        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.autocapitalizationType = .none

        controller.searchBar.delegate = self

        controller.showsSearchResultsController = true

        return controller
    }
}

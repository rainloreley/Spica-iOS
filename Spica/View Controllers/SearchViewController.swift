//
//  SearchViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 17.08.20.
//

import UIKit

class SearchViewController: UIViewController {
    var tableView: UITableView!
    let searchBar = UISearchBar()
    var searchButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Search"

        tableView = UITableView(frame: .zero, style: .plain)
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
        }

        let tableViewHeaderView = UIView()

        searchBar.searchBarStyle = .prominent
        searchBar.placeholder = " Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        /* tableViewHeaderView.addSubview(searchBar)

         searchButton = UIButton(type: .system)
         searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
         searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
         tableViewHeaderView.addSubview(searchButton)
         tableViewHeaderView.addSubview(searchBar)

         searchButton.snp.makeConstraints { (make) in
         	make.height.equalTo(30)
         	make.width.equalTo(30)
         	make.trailing.equalTo(tableViewHeaderView.snp.trailing).offset(-8)
         	make.centerY.equalTo(tableViewHeaderView.snp.centerY)
         }

         searchBar.snp.makeConstraints { (make) in
         	make.centerY.equalTo(tableViewHeaderView.snp.centerY)
         	make.leading.equalTo(tableViewHeaderView.snp.leading).offset(8)
         	make.trailing.equalTo(searchButton.snp.leading).offset(-8)
         } */

        tableView.tableHeaderView = searchBar
        // Do any additional setup after loading the view.
    }

    @objc func search() {}
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        print(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("SEARCHING FOR \(searchBar.text!)")
    }
}

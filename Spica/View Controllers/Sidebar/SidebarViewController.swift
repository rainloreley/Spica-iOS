//
//  SidebarViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 15.07.20.
//

import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
class SidebarViewController: UIViewController, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        splitViewController?.setViewController(SidebarSection(rawValue: indexPath.section)!.viewController, for: .secondary)
    }

    var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.userInterfaceIdiom == .mac {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        navigationItem.title = "Spica"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setLeftBarButton(nil, animated: false)

        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionView = UICollectionView(frame: .init(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        collectionView.delegate = self

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.bottom.equalTo(view.snp.bottom)
            make.trailing.equalTo(view.snp.trailing)
        }

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { cell, _, item in

            var content = cell.defaultContentConfiguration()

            content.text = item.name
            content.image = item.image
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()

        snapshot.appendSections(SidebarSection.allCases)
        snapshot.appendItems([SidebarSection.home.sidebar], toSection: .home)
        snapshot.appendItems([SidebarSection.mentions.sidebar], toSection: .mentions)
        // snapshot.appendItems([SidebarSection.search.sidebar], toSection: .search)
        snapshot.appendItems([SidebarSection.bookmarks.sidebar], toSection: .bookmarks)
        snapshot.appendItems([SidebarSection.account.sidebar], toSection: .account)
        if traitCollection.userInterfaceIdiom != .mac {
            snapshot.appendItems([SidebarSection.settings.sidebar], toSection: .settings)
        }

        dataSource.apply(snapshot)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if targetEnvironment(macCatalyst)
            navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }
}

struct SidebarItem: Hashable {
    let name: String
    let image: UIImage
}

enum SidebarSection: Int, Hashable, CaseIterable {
    case home = 0
    case mentions = 1
    case bookmarks = 2
    // case search = 3
    case account = 3
    case settings = 4

    var sidebar: SidebarItem {
        switch self {
        case .home:
            return SidebarItem(name: SLocale(.HOME), image: UIImage(systemName: "house")!)
        case .mentions:
            return SidebarItem(name: SLocale(.NOTIFICATIONS), image: UIImage(systemName: "bell")!)
        case .bookmarks:
            return SidebarItem(name: SLocale(.BOOKMARKS), image: UIImage(systemName: "bookmark")!)
        /* case .search:
         return SidebarItem(name: "Search", image: UIImage(systemName: "magnifyingglass")!) */
        case .account:
            return SidebarItem(name: SLocale(.ACCOUNT), image: UIImage(systemName: "person.circle")!)
        case .settings:
            return SidebarItem(name: SLocale(.SETTINGS), image: UIImage(systemName: "gear")!)
        }
    }

    var viewController: UIViewController {
        switch self {
        case .home:
            let vc = TimelineViewController()
            vc.navigationItem.hidesBackButton = true
            return vc

        case .mentions:
            let vc = MentionsViewController()
            vc.navigationItem.hidesBackButton = true
            return vc
        case .bookmarks:
            let vc = BookmarksViewController()
            vc.navigationItem.hidesBackButton = true
            return vc

            /* case .search:
             let vc = SearchViewController()
             vc.navigationItem.hidesBackButton = true */
            return vc
        case .account:
            let vc = UserProfileViewController()
            vc.navigationItem.hidesBackButton = true

            let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
            let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name")
            let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag")

            vc.user = User(id: id!, name: name!, tag: tag!)

            vc.hidesBottomBarWhenPushed = true
            return vc
        case .settings:
            let storyboard = UIStoryboard(name: "MainSettings", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! UINavigationController
            vc.navigationItem.hidesBackButton = true
            return vc
        }
    }
}

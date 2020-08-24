//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 15.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
class SidebarViewController: UIViewController, UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        splitViewController?.setViewController(SidebarSection(rawValue: indexPath.section)!.viewController, for: .secondary)
    }

    private var subscriptions = Set<AnyCancellable>()
    var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    var collectionView: UICollectionView!
    var unreadMentions = [String]()

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

            if item.section == .mentions, !self.unreadMentions.isEmpty {
                let dotView = UIView(frame: .zero)
                dotView.backgroundColor = .systemRed
                dotView.layer.cornerRadius = 8
                dotView.tag = 945
                // cell.addSubview(dotView)
                content.secondaryText = "\(self.unreadMentions.count)"
                content.prefersSideBySideTextAndSecondaryText = true
                content.image = UIImage(systemName: "bell.badge.fill")!
                /* dotView.snp.makeConstraints { (make) in
                 	make.width.equalTo(16)
                 	make.height.equalTo(16)
                 	make.top.equalTo(cell.snp.top).offset(-8)
                 	make.leading.equalTo(cell.snp.leading).offset(-8)
                 } */
            } else {
                if let dotView = cell.viewWithTag(945) {
                    dotView.removeFromSuperview()
                }
            }

            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        applyChanges()
    }

    func applyChanges() {
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
        loadNotifications()
        _ = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(loadNotifications), userInfo: nil, repeats: true)
    }

    @objc func loadNotifications() {
        DispatchQueue.global(qos: .utility).async {
            AllesAPI.default.getUnreadMentions()
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        return
                    default: break
                    }
                } receiveValue: { values in
                    // if !arraysAreSame(first: self.unreadMentions, second: values) {
                    self.unreadMentions = values
                    self.applyChanges()
                    // }

                }.store(in: &self.subscriptions)
        }
    }
}

struct SidebarItem: Hashable {
    let name: String
    let image: UIImage
    let section: SidebarSection
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
            return SidebarItem(name: SLocale(.HOME), image: UIImage(systemName: "house")!, section: .home)
        case .mentions:
            return SidebarItem(name: SLocale(.NOTIFICATIONS), image: UIImage(systemName: "bell")!, section: .mentions)
        case .bookmarks:
            return SidebarItem(name: SLocale(.BOOKMARKS), image: UIImage(systemName: "bookmark")!, section: .bookmarks)
        /* case .search:
         return SidebarItem(name: "Search", image: UIImage(systemName: "magnifyingglass")!) */
        case .account:
            return SidebarItem(name: SLocale(.ACCOUNT), image: UIImage(systemName: "person.circle")!, section: .account)
        case .settings:
            return SidebarItem(name: SLocale(.SETTINGS), image: UIImage(systemName: "gear")!, section: .settings)
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
          vc.navigationItem.hidesBackButton = true
         return vc*/
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

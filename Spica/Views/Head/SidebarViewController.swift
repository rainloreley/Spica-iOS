//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
class SidebarViewController: UIViewController {
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var collectionView: UICollectionView!
    private var accountViewController: UserProfileViewController!
    private var secondaryViewControllers = [UINavigationController]()

    var mentionsTimer = Timer()
    var mentions = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Spica"
        navigationController?.navigationBar.prefersLargeTitles = true
        accountViewController = UserProfileViewController(style: .insetGrouped)
        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        accountViewController!.user = User(id: id ?? "")

        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        let settingsViewController = settingsStoryboard.instantiateInitialViewController() as! UINavigationController

        secondaryViewControllers = [UINavigationController(rootViewController: FeedViewController(style: .insetGrouped)),
                                    UINavigationController(rootViewController: MentionsViewController(style: .insetGrouped)),
                                    UINavigationController(rootViewController: BookmarksViewController(style: .insetGrouped)),
                                    UINavigationController(rootViewController: SearchViewController(style: .insetGrouped)),
                                    UINavigationController(rootViewController: accountViewController!),
                                    settingsViewController]
        configureHierarchy()
        configureDataSource()
        setInitialSecondaryView()
    }

    override func viewWillAppear(_: Bool) {
        loadMentionsCount()
        mentionsTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(loadMentionsCount), userInfo: nil, repeats: true)
		NotificationCenter.default.addObserver(self, selector: #selector(loadMentionsCount), name: Notification.Name("loadMentionsCount"), object: nil)
    }

    private func setInitialSecondaryView() {
        collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                  animated: false,
                                  scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
        splitViewController?.setViewController(secondaryViewControllers[0], for: .secondary)
    }

    @objc func loadMentionsCount() {
        MicroAPI.default.getUnreadMentions(allowError: false) { [self] result in
            switch result {
            case .failure:
                break
            case let .success(loadedMentions):
                if mentions.count != loadedMentions.count {
                    DispatchQueue.main.async {
                        mentions = loadedMentions
                        if mentions.count > 0 {
                            tabsItems[1].image = UIImage(systemName: "bell.badge.fill")
                            configureDataSource()
                        } else {
                            tabsItems[1].image = UIImage(systemName: "bell")
                            configureDataSource()
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 14.0, *)
extension SidebarViewController {
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
}

@available(iOS 14.0, *)
extension SidebarViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.delegate = self

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [self] cell, index, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image
            if index.section == 0, index.row == 1, mentions.count > 0 {
                content.secondaryText = "\(mentions.count)"
                content.prefersSideBySideTextAndSecondaryText = true
            }
            cell.contentConfiguration = content
            cell.accessories = []
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            if indexPath.item == 0, indexPath.section != 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }

        let sections: [Section] = [.tabs]
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        for section in sections {
            switch section {
            case .tabs:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
                sectionSnapshot.append(tabsItems)
                dataSource.apply(sectionSnapshot, to: section)
            }
        }
    }
}

@available(iOS 14.0, *)
extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        splitViewController?.setViewController(secondaryViewControllers[indexPath.row], for: .secondary)
    }
}

struct Item: Hashable {
    let title: String?
    var image: UIImage?
    private let identifier = UUID()
}

var tabsItems = [
	Item(title: "Feed", image: UIImage(systemName: "house")),
	Item(title: "Mentions", image: UIImage(systemName: "bell")),
	Item(title: "Bookmarks", image: UIImage(systemName: "bookmark")),
	Item(title: "Search", image: UIImage(systemName: "magnifyingglass")),
	Item(title: "Account", image: UIImage(systemName: "person.circle")),
	Item(title: "Settings", image: UIImage(systemName: "gear"))]

enum Section: String {
    case tabs
}

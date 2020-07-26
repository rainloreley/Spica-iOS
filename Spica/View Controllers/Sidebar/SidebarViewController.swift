//
//  SidebarViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 15.07.20.
//

import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
class SidebarViewController: UIViewController, UICollectionViewDelegate, UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        //splitViewController?.showDetailViewController(SidebarSection(rawValue: indexPath.section)!.viewController, sender: nil)
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		splitViewController?.setViewController(SidebarSection(rawValue: indexPath.section)!.viewController, for: .secondary)
        //splitViewController?.showDetailViewController(SidebarSection(rawValue: indexPath.section)!.viewController, sender: nil)
		//splitViewController?.setViewController(SidebarSection(rawValue: indexPath.section)!.viewController, for: .secondary)
		//navigationController?.setViewControllers([SidebarSection(rawValue: indexPath.section)!.viewController], animated: true)
    }

    var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    var collectionView: UICollectionView!

    /* var tableView: UITableView!

     private lazy var dataSource = makeDataSource() */

    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.userInterfaceIdiom == .mac {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        navigationItem.title = "Spica"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setLeftBarButton(nil, animated: false)

        // view.backgroundColor = .systemBackground

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
            // content.image = UIImage(systemName: "scribble.variable")
            // content.image = UIImage.circle(diameter: 20, color: hexStringToUIColor(hex: item.color))
            content.image = item.image
            // content.imageProperties.tintColor = .orange

            cell.contentConfiguration = content

            /* let dropInteraction = UIDropInteraction(delegate: self)

             cell.addInteraction(dropInteraction)
             dropInteraction.view!.tag = Int("9\(index.section)\(index.row)")!
             self.latestDropID = item.id ?? "" */
        }

        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()

        snapshot.appendSections(SidebarSection.allCases)
        snapshot.appendItems([SidebarSection.home.sidebar], toSection: .home)
        snapshot.appendItems([SidebarSection.mentions.sidebar], toSection: .mentions)
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

    /* func makeDataSource() -> UITableViewDiffableDataSource<Section, SidebarItem> {
         let source = UITableViewDiffableDataSource<Section, SidebarItem>(tableView: tableView) { (_, _, post) -> UITableViewCell? in
             let cell = UITableViewCell()

             cell.textLabel?.text = post.name
             cell.imageView?.image = post.image

             return cell
         }
         source.defaultRowAnimation = .fade
         return source
     }

     func applyChanges(_ animated: Bool = true) {
         var snapshot = NSDiffableDataSourceSnapshot<Section, SidebarItem>()
         snapshot.appendSections(Section.allCases)
         snapshot.appendItems([Section.home.sidebar], toSection: .home)
         snapshot.appendItems([Section.mentions.sidebar], toSection: .mentions)
         snapshot.appendItems([Section.settings.sidebar], toSection: .settings)
         DispatchQueue.main.async {
             self.dataSource.apply(snapshot, animatingDifferences: animated)
         }
     } */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

struct SidebarItem: Hashable {
    let name: String
    let image: UIImage
}

enum SidebarSection: Int, Hashable, CaseIterable {
    case home = 0
    case mentions = 1
    case bookmarks = 2
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
        case .account:
            let vc = UserProfileViewController()
            vc.navigationItem.hidesBackButton = true
            let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")
            vc.user = User(id: "", username: username!, displayName: username!, nickname: username!, imageURL: URL(string: "https://avatar.alles.cx/u/\(username!)")!, isPlus: false, rubies: 0, followers: 0, image: ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username!)")!), isFollowing: false, followsMe: false, about: "", isOnline: false)
            vc.hidesBottomBarWhenPushed = true
            return vc
        case .settings:
            let storyboard = UIStoryboard(name: "MainSettings", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! UINavigationController
            vc.navigationItem.hidesBackButton = true
            // (vc.viewControllers.first as! MainSettingsViewController).delegate = self
            return vc
        }
    }
}

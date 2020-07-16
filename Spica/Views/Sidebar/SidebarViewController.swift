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
        splitViewController?.showDetailViewController(Section(rawValue: indexPath.section)!.viewController, sender: nil)
    }

    var tableView: UITableView!

    private lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = dataSource

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
        }

        if traitCollection.userInterfaceIdiom == .mac {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        navigationItem.title = "Spica"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setLeftBarButton(nil, animated: false)

        applyChanges()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_: Bool) {
        /* DispatchQueue.global(qos: .utility).async {
         	let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")!
         	let image = ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(username)")!)
         	DispatchQueue.main.async {
         		//self.userPfpView.image = image
         	}
         } */
    }

    func makeDataSource() -> UITableViewDiffableDataSource<Section, SidebarItem> {
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
    }

    enum Section: Int, Hashable, CaseIterable {
        case home = 0
        case mentions = 1
        case settings = 2

        var sidebar: SidebarItem {
            switch self {
            case .home:
                return SidebarItem(name: "Home", image: UIImage(systemName: "house")!)
            case .mentions:
                return SidebarItem(name: "Notifications", image: UIImage(systemName: "bell")!)
            case .settings:
                return SidebarItem(name: "Settings", image: UIImage(systemName: "gear")!)
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
            case .settings:
                let storyboard = UIStoryboard(name: "MainSettings", bundle: nil)
                let vc = storyboard.instantiateInitialViewController() as! UINavigationController
                // (vc.viewControllers.first as! MainSettingsViewController).delegate = self
                return vc
            }
        }
    }

    struct SidebarItem: Hashable {
        let name: String
        let image: UIImage
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

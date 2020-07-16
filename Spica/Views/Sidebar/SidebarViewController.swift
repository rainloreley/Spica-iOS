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
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		splitViewController?.showDetailViewController(Section(rawValue: indexPath.section)!.viewController, sender: nil)
	}
	
	var dataSource: UICollectionViewDiffableDataSource<Section, SidebarItem>!
	var collectionView: UICollectionView!

    /*var tableView: UITableView!

	private lazy var dataSource = makeDataSource()*/

    override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		}

		navigationItem.title = "Spica"
		navigationController?.navigationBar.prefersLargeTitles = true
		navigationItem.setLeftBarButton(nil, animated: false)
		
		//view.backgroundColor = .systemBackground
		
		let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
		let layout = UICollectionViewCompositionalLayout.list(using: configuration)
		collectionView = UICollectionView(frame: .init(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), collectionViewLayout: layout)
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		collectionView.delegate = self
		
		view.addSubview(collectionView)
		
		collectionView.snp.makeConstraints { (make) in
			make.top.equalTo(view.snp.top)
			make.leading.equalTo(view.snp.leading)
			make.bottom.equalTo(view.snp.bottom)
			make.trailing.equalTo(view.snp.trailing)
		}
		
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { cell, index, item in

			var content = cell.defaultContentConfiguration()

			content.text = item.name
			// content.image = UIImage(systemName: "scribble.variable")
			//content.image = UIImage.circle(diameter: 20, color: hexStringToUIColor(hex: item.color))
			content.image = item.image
			//content.imageProperties.tintColor = .orange

			cell.contentConfiguration = content

			/*let dropInteraction = UIDropInteraction(delegate: self)

			cell.addInteraction(dropInteraction)
			dropInteraction.view!.tag = Int("9\(index.section)\(index.row)")!
			self.latestDropID = item.id ?? ""*/
		}

		dataSource = UICollectionViewDiffableDataSource<Section, SidebarItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
			collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Section, SidebarItem>()
		
		snapshot.appendSections(Section.allCases)
		snapshot.appendItems([Section.home.sidebar], toSection: .home)
		snapshot.appendItems([Section.mentions.sidebar], toSection: .mentions)
		snapshot.appendItems([Section.settings.sidebar], toSection: .settings)
		
		dataSource.apply(snapshot)
		
		
		
		// collectionView.dragInteractionEnabled = true
		// collectionView.dropDelegate = self
		

        /*tableView = UITableView(frame: .zero, style: .insetGrouped)
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

        applyChanges()*/

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

    /*func makeDataSource() -> UITableViewDiffableDataSource<Section, SidebarItem> {
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
    }*/

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

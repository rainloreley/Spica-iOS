//
//  MainSettingsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import SwiftKeychainWrapper
import UIKit

protocol MainSettingsDelegate {
    func clickedMore(username: String)
}

class MainSettingsViewController: UITableViewController {
    @IBOutlet var userPfpImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var versionBuildLabel: UILabel!

    // Outlets for Localization
    @IBOutlet var goToProfileButton: UIButton!
    @IBOutlet var SignOutButton: UIButton!

    @IBOutlet var spicaPrivacyButton: UIButton!
    @IBOutlet var spicaWebsiteButton: UIButton!

    @IBOutlet var allesPrivacyButton: UIButton!
    @IBOutlet var allesTOSButton: UIButton!
    @IBOutlet var allesWebsiteButton: UIButton!

    @IBOutlet var usedLibrariesButton: UIButton!
    @IBOutlet var creditsButton: UIButton!

    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var translateAppLabel: UIButton!
    @IBOutlet var contactLabel: UIButton!

    var username = ""

    var delegate: MainSettingsDelegate!

    func localizeView() {
        goToProfileButton.setTitle(SLocale(.GO_TO_PROFILE), for: .normal)
        SignOutButton.setTitle(SLocale(.SIGN_OUT), for: .normal)

        spicaPrivacyButton.setTitle(SLocale(.PRIVACY_POLICY), for: .normal)
        spicaWebsiteButton.setTitle(SLocale(.WEBSITE), for: .normal)

        allesPrivacyButton.setTitle(SLocale(.PRIVACY_POLICY), for: .normal)
        allesTOSButton.setTitle(SLocale(.TERMS_OF_SERVICE), for: .normal)
        allesWebsiteButton.setTitle(SLocale(.WEBSITE), for: .normal)

        usedLibrariesButton.setTitle(SLocale(.USED_LIBRARIES), for: .normal)
        creditsButton.setTitle(SLocale(.CREDITS), for: .normal)

        copyrightLabel.text = SLocale(.SPICA_COPYRIGHT)
        translateAppLabel.setTitle(SLocale(.TRANSLATE_APP), for: .normal)
        contactLabel.setTitle(SLocale(.CONTACT), for: .normal)
    }

    @IBAction func profileMore(_: Any) {
        if let splitViewController = splitViewController, !splitViewController.isCollapsed {
            let vc = UserProfileViewController()
            vc.user = User(id: username, username: username, displayName: username, nickname: username, imageURL: URL(string: "https://avatar.alles.cx/u/\(username)")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle")!, isFollowing: false, followsMe: false, about: "", isOnline: false)
            vc.hidesBottomBarWhenPushed = true

            navigationController?.pushViewController(vc, animated: true)
        } else {
            dismiss(animated: true)
            if delegate != nil {
                delegate.clickedMore(username: username)
            }
        }
    }

    @IBAction func translateApp(_: Any) {
        let url = URL(string: "https://go.fliney.eu/BWhtmsECgJ49")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func github(_: Any) {
        let url = URL(string: "https://github.com/adrianbaumgart/Spica")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func contact(_: Any) {
        let url = URL(string: "mailto:adrian@abmgrt.dev")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func signOut(_: Any) {
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
        let mySceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
        mySceneDelegate.window?.makeKeyAndVisible()
    }

    @IBAction func spicaPrivacy(_: Any) {
        let url = URL(string: "https://spica.fliney.eu/privacy")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func spicaWebsite(_: Any) {
        let url = URL(string: "https://spica.fliney.eu/")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func allesPrivacy(_: Any) {
        let url = URL(string: "https://alles.cx/docs/privacy")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func allesTerms(_: Any) {
        let url = URL(string: "https://alles.cx/docs/terms")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func allesWebsite(_: Any) {
        let url = URL(string: "https://alles.cx/")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func usedLibraries(_: Any) {
        navigationController?.pushViewController(UsedLibrariesViewController(), animated: true)
    }

    @IBAction func credits(_: Any) {
        navigationController?.pushViewController(CreditsViewController(), animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SLocale(.SETTINGS)
        /* tableView = UITableView(frame: .zero, style: .insetGrouped)
         tableView.delegate = self
         tableView.dataSource = self
         view.addSubview(tableView)
         tableView.snp.makeConstraints { (make) in
         	make.top.equalTo(view.snp.top)
         	make.leading.equalTo(view.snp.leading)
         	make.bottom.equalTo(view.snp.bottom)
         	make.trailing.equalTo(view.snp.trailing)
         } */
        // self.tableView.delegate = self
        localizeView()
    }

    func setSidebar() {
        if #available(iOS 14.0, *) {
            if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                if let sidebar = globalSideBarController {
                    if let collectionView = sidebar.collectionView {
                        collectionView.selectItem(at: IndexPath(row: 0, section: SidebarSection.settings.rawValue), animated: true, scrollPosition: .top)
                    }
                }
            }
        }
    }

    override func viewWillAppear(_: Bool) {
        setSidebar()
        navigationController?.navigationBar.prefersLargeTitles = true

        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String

        versionBuildLabel.text = "\(SLocale(.VERSION)) \(version) \(SLocale(.BUILD)) \(build)"

        DispatchQueue.global(qos: .background).async {
            self.username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")!

            let userImage = ImageLoader.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(self.username)")!)

            DispatchQueue.main.async {
                self.usernameLabel.text = "@\(self.username)"
                self.userPfpImageView.image = userImage
            }
        }
    }

    override func viewDidAppear(_: Bool) {
        setSidebar()

        #if targetEnvironment(macCatalyst)
            let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
            if let titleBar = sceneDelegate.window?.windowScene?.titlebar {
                let toolBar = NSToolbar(identifier: "settingsToolbar")

                titleBar.toolbar = toolBar
            }
        #endif
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        // return tableViewData[section].title
        switch section {
        case 0:
            return SLocale(.ACCOUNT)
        case 1:
            return "Spica"
        case 2:
            return "Alles"
        case 3:
            return SLocale(.OTHER)
        case 4:
            return ""
        default:
            return ""
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        // return tableViewData.count

        return 5
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        // return tableViewData[section].cells.count

        switch section {
        case 0:
            return 3
        case 1:
            return 2
        case 2:
            return 3
        case 3:
            return 5
        case 4:
            return 2
        default:
            return 0
        }
    }

    /* func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     	let cell = UITableViewCell()

     	return cell
     }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     	<#code#>
     }

     struct Section {
     	var title: String?
     	var cells: [Cell]
     }

     struct Cell {
     	var image: UIImage?
     	var title: String?
     } */
}

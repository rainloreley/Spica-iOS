//
//  MainSettingsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import Cache
import LocalAuthentication
import SPAlert
import SwiftKeychainWrapper
import UIKit
import Combine

protocol MainSettingsDelegate {
    func clickedMore(username: String)
}

class MainSettingsViewController: UITableViewController {
	
	var toolbarDelegate = ToolbarDelegate()
	private var navigateBackSubscriber: AnyCancellable?
	
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

    @IBOutlet var translateSymbol: UIImageView!
    @IBOutlet var clearCacheButton: UIButton!

    @IBOutlet var biometricsLabel: UILabel!
    @IBOutlet var biometricsSwitch: UISwitch!

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
        clearCacheButton.setTitle(SLocale(.CLEAR_CACHE), for: .normal)

        biometricsLabel.text = SLocale(.BIOMETRICS)
    }

    @IBAction func toggleBiometrics(_: Any) {
        let context = LAContext()
        var error: NSError?
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            UserDefaults.standard.set(biometricsSwitch.isOn, forKey: "biometricAuthEnabled")
            appDelegate?.sessionAuthorized = true
        } else {
            appDelegate?.sessionAuthorized = true
            biometricsSwitch.isEnabled = false
            biometricsSwitch.setOn(false, animated: true)
            UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")

            var type = "FaceID / TouchID"
            let biometric = biometricType()
            switch biometric {
            case .face:
                type = "FaceID"
            case .touch:
                type = "TouchID"
            case .none:
                type = "FaceID / TouchID"
            }
            EZAlertController.alert(SLocale(.DEVICE_ERROR), message: String(format: SLocale(.BIOMETRIC_DEVICE_NOTAVAILABLE), "\(type)", "\(type)"))
        }
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

    @IBAction func clearCache(_: Any) {
        /* let realm = try! Realm()

         try! realm.write {
             realm.deleteAll()
         } */

        /* let path = realm.configuration.fileURL?.relativePath
         let subPaths = try? FileManager.default.contentsOfDirectory(atPath: path!)
         for i in subPaths ?? [] {
         	print("SUBPATH: \(i)")
         	try! FileManager.default.removeItem(atPath: i)
         }
         let attributes = try! FileManager.default.attributesOfItem(atPath: path!)

         let fileSize = attributes[.size]
         let mbFile = ByteCountFormatter.string(fromByteCount: Int64("\(fileSize!)")!, countStyle: .file)
         print("MBFIII: \(mbFile)") */
        // cacheSizeLabel.text = "\(mbFile)"
        // cacheSizeLabel.text = "\(fileSize)"
        /* let diskConfig = DiskConfig(name: "SpicaImageCache")
         let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)

         let storage = try? Storage(
           diskConfig: diskConfig,
           memoryConfig: memoryConfig,
           transformer: TransformerFactory.forCodable(ofType: Data.self) // Storage<User>
         )

         try? storage?.removeAll() */

        // SPAlert.present(title: SLocale(.CACHE_CLEARED), preset: .done)
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

        /* let realm = try! Realm()

         let path = realm.configuration.fileURL!.path
         let attributes = try! FileManager.default.attributesOfItem(atPath: path)
         let fileSize = attributes[.size]
         cacheSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64("\(fileSize!)")!, countStyle: .file))" */

        /* if #available(iOS 14.0, *) {
         translateSymbol.image = UIImage(systemName: "translate")
         } else { */
        translateSymbol.image = UIImage(named: "translate")
        translateSymbol.image = translateSymbol.image?.withRenderingMode(.alwaysTemplate)
        translateSymbol.tintColor = .link
        // }
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
	
	override func viewWillDisappear(_ animated: Bool) {
		navigateBackSubscriber?.cancel()
	}
	
	@objc func navigateBack() {
		if (navigationController?.viewControllers.count)! > 1 {
			navigationController?.popViewController(animated: true)
		}
	}

	
    func setSidebar() {
        if #available(iOS 14.0, *) {
            if let splitViewController = splitViewController, !splitViewController.isCollapsed {
                if let sidebar = globalSideBarController {
					navigationController?.viewControllers = [self]
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
		
		let notificationCenter = NotificationCenter.default
		navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
			.receive(on: RunLoop.main)
			.sink(receiveValue: { notificationCenter in
				self.navigateBack()
			})

        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String

        versionBuildLabel.text = "\(SLocale(.VERSION)) \(version) \(SLocale(.BUILD)) \(build)"

        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsSwitch.isEnabled = true
        } else {
            biometricsSwitch.isEnabled = false
        }

        if UserDefaults.standard.bool(forKey: "biometricAuthEnabled") {
            biometricsSwitch.setOn(true, animated: false)
        } else {
            biometricsSwitch.setOn(false, animated: false)
        }

        /* let realm = try! Realm()

         let path = realm.configuration.fileURL?.relativePath
         let attributes = try! FileManager.default.attributesOfItem(atPath: path!)
         let fileSize = attributes[.size]
         cacheSizeLabel.text = "\(ByteCountFormatter.string(fromByteCount: Int64("\(fileSize!)")!, countStyle: .file))" */
        // cacheSizeLabel.text = "\(fileSize)"

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
		#if targetEnvironment(macCatalyst)
		
			let toolbar = NSToolbar(identifier: "settings")
		toolbarDelegate.navStack = (navigationController?.viewControllers)!
			toolbar.delegate = toolbarDelegate
			toolbar.displayMode = .iconOnly
		
			if let titlebar = view.window!.windowScene!.titlebar {
				titlebar.toolbar = toolbar
				titlebar.toolbarStyle = .automatic
			}
	
			navigationController?.setNavigationBarHidden(true, animated: false)
			navigationController?.setToolbarHidden(true, animated: false)
		#endif
        setSidebar()

        /* #if targetEnvironment(macCatalyst)
             let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
             if let titleBar = sceneDelegate.window?.windowScene?.titlebar {
                 let toolBar = NSToolbar(identifier: "settingsToolbar")

                 titleBar.toolbar = toolBar
             }
         #endif */
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        // return tableViewData[section].title
        switch section {
        case 0:
            return SLocale(.ACCOUNT)
        case 1:
            return SLocale(.SETTINGS)
        case 2:
            return "Spica"
        case 3:
            return "Alles"
        case 4:
            return SLocale(.OTHER)
        case 5:
            return ""
        default:
            return ""
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        // return tableViewData.count

        return 6
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        // return tableViewData[section].cells.count

        switch section {
        case 0:
            return 3
        case 1:
            return 1
        case 2:
            return 2
        case 3:
            return 3
        case 4:
            return 5
        case 5:
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

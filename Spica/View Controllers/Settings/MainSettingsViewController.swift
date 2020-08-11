//
//  MainSettingsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import Cache
import Combine
import LocalAuthentication
import SPAlert
import SwiftKeychainWrapper
import UIKit

protocol MainSettingsDelegate {
    func clickedMore(username: String)
}

class MainSettingsViewController: UITableViewController {
    var toolbarDelegate = ToolbarDelegate()
    private var navigateBackSubscriber: AnyCancellable?

    @IBOutlet var userPfpImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var versionBuildLabel: UILabel!

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
            vc.user = User.empty(id: username, username: username, displayName: username, nickname: username)
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

    @IBAction func clearCache(_: Any) {}

    @IBAction func github(_: Any) {
        let url = URL(string: "https://github.com/SpicaApp/Spica-iOS")
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
        UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
        let mySceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
        mySceneDelegate.window?.makeKeyAndVisible()
    }

    @IBAction func spicaPrivacy(_: Any) {
        let url = URL(string: "https://spica.li/privacy")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }

    @IBAction func spicaWebsite(_: Any) {
        let url = URL(string: "https://spica.li/")
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
        translateSymbol.image = UIImage(named: "translate")
        translateSymbol.image = translateSymbol.image?.withRenderingMode(.alwaysTemplate)
        translateSymbol.tintColor = .link
        localizeView()
    }

    override func viewWillDisappear(_: Bool) {
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
            .sink(receiveValue: { _ in
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
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    override func numberOfSections(in _: UITableView) -> Int {
        return 6
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
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
}

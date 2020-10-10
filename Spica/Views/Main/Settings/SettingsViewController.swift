//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftKeychainWrapper
import SwiftUI
import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet var accountProfilePicture: UIImageView!
    @IBOutlet var accountNametag: UILabel!
    @IBOutlet var versionBuildLabel: UILabel!

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true

        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String

        versionBuildLabel.text = "Version \(version) Build \(build)"

        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id") ?? "_"
        let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name") ?? ""
        let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag") ?? ""

        accountNametag.text = "\(name)#\(tag)"
        accountProfilePicture.kf.setImage(with: URL(string: "https://avatar.alles.cc/\(id)"))
    }

    var colorPickerController: ColorPickerController!
    var changeAccentColorSheet = UIAlertController(title: "Change accent color", message: "", preferredStyle: .actionSheet)

    @IBAction func changeAccentColor(_: UIButton) {
        changeAccentColorSheet = UIAlertController(title: "Change accent color", message: "", preferredStyle: .actionSheet)

        let currentAccentColor = UserDefaults.standard.colorForKey(key: "globalTintColor")
        colorPickerController = ColorPickerController(color: Color(currentAccentColor ?? UIColor.systemBlue))
        colorPickerController.delegate = self

        if let popoverController = changeAccentColorSheet.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        let height: NSLayoutConstraint = NSLayoutConstraint(item: changeAccentColorSheet.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 200)
        changeAccentColorSheet.view.addConstraint(height)

        let exitBtn: UIButton! = {
            let btn = UIButton(type: .close)
            btn.tintColor = .gray
            btn.addTarget(self, action: #selector(closeAccentSheet), for: .touchUpInside)
            return btn
        }()

        changeAccentColorSheet.view.addSubview(exitBtn)
        exitBtn.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
        }

        let colorPickerView = UIHostingController(rootView: ColorPickerView(controller: colorPickerController)).view
        colorPickerView?.backgroundColor = .none

        changeAccentColorSheet.view.addSubview(colorPickerView!)
        colorPickerView?.snp.makeConstraints { make in
            make.center.equalTo(changeAccentColorSheet.view.snp.center)
            make.top.equalTo(changeAccentColorSheet.view.snp.top).offset(48)
            make.leading.equalTo(changeAccentColorSheet.view.snp.leading).offset(8)
            make.trailing.equalTo(changeAccentColorSheet.view.snp.trailing).offset(-8)
            make.bottom.equalTo(changeAccentColorSheet.view.snp.bottom).offset(-8)
        }

        present(changeAccentColorSheet, animated: true, completion: nil)
    }

    @objc func closeAccentSheet() {
        changeAccentColorSheet.dismiss(animated: true, completion: nil)
    }

    @IBAction func spicaButtons(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let url = URL(string: "https://spica.li/privacy")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        case 1:
            break
        case 2:
            let url = URL(string: "https://spica.li/")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        default: break
        }
    }
	
	@IBAction func signOut(_ sender: Any) {
		KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.name")
		KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.tag")
		KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
		KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
		UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
		let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
		sceneDelegate.window?.rootViewController = sceneDelegate.loadInitialViewController()
		sceneDelegate.window?.makeKeyAndVisible()
	}
	
    @IBAction func allesMicroButtons(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let url = URL(string: "https://files.alles.cc/Documents/Privacy%20Policy.txt")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        case 1:
            let url = URL(string: "https://files.alles.cc/Documents/Terms%20of%20Service.txt")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        case 2:
            let url = URL(string: "https://micro.alles.cx")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        default: break
        }
    }

    @IBAction func githubAction(_: Any) {
        let url = URL(string: "https://github.com/SpicaApp/Spica-iOS")!
        if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
    }

    @IBAction func contactAction(_: Any) {
        let url = URL(string: "mailto:adrian@abmgrt.dev")!
        if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 6
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Account
        case 1: return 2 // Settings
        case 2: return 3 // Spica
        case 3: return 3 // Alles Micro
        case 4: return 4 // Other
        case 5: return 2 // About
        default: return 0
        }
    }
}

extension SettingsViewController: ColorPickerControllerDelegate {
    func changedColor(_ color: UIColor) {
        UserDefaults.standard.setColor(color: color, forKey: "globalTintColor")
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.window?.tintColor = color
    }
}

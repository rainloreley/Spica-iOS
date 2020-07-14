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

    var username = ""

    var delegate: MainSettingsDelegate!

    @IBAction func profileMore(_: Any) {
        dismiss(animated: true, completion: nil)
        delegate.clickedMore(username: username)
    }

    @IBAction func signOut(_: Any) {
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
        KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
        let mySceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate
        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
        mySceneDelegate.window?.makeKeyAndVisible()
    }

	@IBAction func spicaPrivacy(_ sender: Any) {
		let url = URL(string: "https://spica.fliney.eu/privacy")
		if UIApplication.shared.canOpenURL(url!) {
			UIApplication.shared.open(url!)
		}
	}
	
	@IBAction func spicaWebsite(_ sender: Any) {
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
	
	@IBAction func allesWebsite(_ sender: Any) {
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_: Bool) {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String

        versionBuildLabel.text = "Version \(version) Build \(build)"

        DispatchQueue.global(qos: .utility).async {
            self.username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")!

            DispatchQueue.main.async {
                self.usernameLabel.text = "@\(self.username)"
            }

            let userImage = ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(self.username)")!)

            DispatchQueue.main.async {
                self.userPfpImageView.image = userImage
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 5
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        case 2:
			return 3
        case 3:
            return 2
        case 4:
            return 2
        default:
            return 0
        }
    }
}

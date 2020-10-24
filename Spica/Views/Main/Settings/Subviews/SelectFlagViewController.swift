//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 24.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SPAlert
import SwiftKeychainWrapper
import UIKit

class SelectFlagViewController: UITableViewController {
    var flags = [
        Flag(name: "None", description: "Disable the flag around your profile picture", ring: .none),
        Flag(name: "Rainbow Pride Flag", description: "The rainbow pride flag", ring: .rainbow),
        Flag(name: "Transgender Pride Flag", description: "The transgender pride flag", ring: .trans),
        Flag(name: "Bisexual Pride Flag", description: "The bisexual pride flag", ring: .bisexual),
        Flag(name: "Pansexual Pride Flag", description: "The pansexual pride flag", ring: .pansexual),
        Flag(name: "Lesbian Pride Flag", description: "The lesbian pride flag", ring: .lesbian),
        Flag(name: "Asexual Pride Flag", description: "The asexual pride flag", ring: .asexual),
        Flag(name: "Genderqueer Pride Flag", description: "The genderqueer pride flag", ring: .genderqueer),
        Flag(name: "Genderfluid Pride Flag", description: "The genderfluid pride flag", ring: .genderfluid),
        Flag(name: "Agender Pride Flag", description: "The agender pride flag", ring: .agender),
        Flag(name: "Non-Binary Pride flag", description: "The non-binary pride flag", ring: .nonbinary),
    ]

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Select a flag"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
		if CreditsViewController().credits.contains(where: { $0.allesUID == signedInID! } ) {
			flags.append(Flag(name: "Spica Supporter Flag", description: "A ✨ special ✨ flag because you helped developing Spica!", ring: .supporter))
		}
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return flags.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let flag = flags[indexPath.section]
        cell.textLabel?.text = flag.name
        cell.textLabel?.font = .boldSystemFont(ofSize: 20)
        cell.detailTextLabel?.text = flag.description
		cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        // Configure the cell...

        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFlag = flags[indexPath.section]
        let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        MicroAPI.default.updateUserRing(selectedFlag.ring, id: signedInID!) { result in
            switch result {
            case let .failure(err):
                DispatchQueue.main.async {
                    MicroAPI.default.errorHandling(error: err, caller: self.view)
                }
            case .success:
                DispatchQueue.main.async {
                    SPAlert.present(title: "Flag updated!", preset: .done)
                }
            }
        }
    }

    override func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == flags.count - 1 {
            return """

            You can select a flag here, which will be shown around the profile picture on your profile picture. It is visible to anyone else.
            Note: this is a Spica feature, so it'll only show if you use Spica 0.9.1 beta 16 or higher

            There is a ✨ special ✨ flag for people in \"Credits\". If you're mentioned there but you don't see the special flag, please contact me, thanks!


            """
        } else {
            return ""
        }
    }
}

struct Flag {
    var name: String
    var description: String
    var ring: ProfileRing
}

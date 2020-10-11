//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class CreditsViewController: UITableViewController {
    var credits = [
        Credit(name: "Lea Baumgart", description: "iOS Developer", twitterURL: URL(string: "https://twitter.com/leabmgrt")!, allesUID: "87cd0529-f41b-4075-a002-059bf2311ce7", imageURL: URL(string: "https://avatar.alles.cc/87cd0529-f41b-4075-a002-059bf2311ce7")!),
        Credit(name: "Archie Baer", description: "Alles Founder", twitterURL: URL(string: "https://twitter.com/onlytruearchie")!, allesUID: "00000000-0000-0000-0000-000000000000", imageURL: URL(string: "https://avatar.alles.cc/00000000-0000-0000-0000-000000000000")!),
        Credit(name: "Patrik Svoboda", description: "iOS Developer", twitterURL: URL(string: "https://twitter.com/PatrikTheDev")!, allesUID: "f2d1821d-6bd6-4e26-959f-885428cf8a9b", imageURL: URL(string: "https://pbs.twimg.com/profile_images/1257940562801577984/eWJ4Sp-i_400x400.jpg")!),
        Credit(name: "Jason", description: "Android Developer", twitterURL: URL(string: "https://twitter.com/jso_8910")!, allesUID: "0b528866-df2c-4323-9498-7b4b417b0023", imageURL: URL(string: "https://avatar.alles.cc/0b528866-df2c-4323-9498-7b4b417b0023")!),
        Credit(name: "David Muñoz", description: "Translator (Spanish)", twitterURL: URL(string: "https://twitter.com/Dmunozv04")!, imageURL: URL(string: "https://crowdin-static.downloads.crowdin.com/avatar/13940729/small/bf4ab120766769e9c9deed4b51c2661c.jpg")!),
        Credit(name: "James Young", description: "Translator (French, Norwegian)", twitterURL: URL(string: "https://twitter.com/onlytruejames")!, allesUID: "af3a1a9e-b0e1-418e-8b4c-76605897eeab", imageURL: URL(string: "https://avatar.alles.cc/af3a1a9e-b0e1-418e-8b4c-76605897eeab")!),
        Credit(name: "@DaThinkingChair", description: "Translator (Spanish)", twitterURL: URL(string: "https://twitter.com/DaThinkingChair")!, imageURL: URL(string: "https://pbs.twimg.com/profile_images/1259314332950769666/UPvu5g-e_400x400.jpg")!),
        Credit(name: "Storm", description: "Translator (Norwegian)", twitterURL: URL(string: "https://twitter.com/StormLovesTech")!, allesUID: "43753811-5856-4d98-93a3-ed8763e9176e", imageURL: URL(string: "https://avatar.alles.cc/43753811-5856-4d98-93a3-ed8763e9176e")!),
        Credit(name: "primenate32", description: "Translator (Frensh, Spanish)", twitterURL: URL(string: "https://twitter.com/n8_64")!, allesUID: "daf52a37-667a-4434-8dcc-c6fa1f9fa508", imageURL: URL(string: "https://pbs.twimg.com/profile_images/1312457889966182402/ygvafSTw_400x400.jpg")!),
        Credit(name: "grify", description: "Translator (Swedish)", twitterURL: URL(string: "https://twitter.com/GrifyDev")!, allesUID: "181cbcb1-5bf4-43f1-9ec9-0b36e67ab02d", imageURL: URL(string: "https://avatar.alles.cc/181cbcb1-5bf4-43f1-9ec9-0b36e67ab02d")!),
    ]

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Credits"
        tableView.delegate = self
        tableView.rowHeight = CGFloat(70)
        tableView.register(CreditsCell.self, forCellReuseIdentifier: "creditsCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return credits.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    override func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == credits.count - 1 {
            return """

            Hello there! 👋

            Thank you for reading this. Without these awesome people, this app wouldn't be possible!
            Also thank you to everyone testing the app, giving feedback and reporting bugs!

            ily <3

            ~ Lea

            """
        } else {
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "creditsCell", for: indexPath) as! CreditsCell

        cell.creditUser = credits[indexPath.section]

        return cell
    }
}

extension CreditsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if credits[indexPath.section].allesUID != nil {
            let url = URL(string: "spica://user/\(credits[indexPath.section].allesUID!)")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!)
            }
        } else {
            if UIApplication.shared.canOpenURL(credits[indexPath.section].twitterURL) {
                UIApplication.shared.open(credits[indexPath.section].twitterURL)
            }
        }
    }
}

struct Credit {
    var name: String
    var description: String
    var twitterURL: URL
    var allesUID: String?
    var imageURL: URL
}

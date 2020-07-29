//
//  CreditsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import UIKit

class CreditsViewController: UIViewController {
    var tableView: UITableView!
    var toolbarDelegate = ToolbarDelegate()

    var credits = [
        Credit(name: "Adrian Baumgart", role: "iOS Developer", url: "https://twitter.com/adrianbaumgart", imageURL: "https://avatar.alles.cx/u/adrian", image: UIImage(systemName: "person.circle")!),
        Credit(name: "Patrik Svoboda", role: "iOS Developer", url: "https://twitter.com/PatrikTheDev", imageURL: "https://pbs.twimg.com/profile_images/1257940562801577984/eWJ4Sp-i_400x400.jpg", image: UIImage(systemName: "person.circle")!),
        Credit(name: "Archie Baer", role: "Alles Founder", url: "https://twitter.com/onlytruearchie", imageURL: "https://avatar.alles.cx/u/archie", image: UIImage(systemName: "person.circle")!),
        Credit(name: "David Muñoz", role: "Translator (Spanish)", url: "https://twitter.com/Dmunozv04", imageURL: "https://crowdin-static.downloads.crowdin.com/avatar/13940729/small/bf4ab120766769e9c9deed4b51c2661c.jpg", image: UIImage(systemName: "person.circle")!),
        Credit(name: "James Young", role: "Translator (French, Norwegian)", url: "https://twitter.com/onlytruejames", imageURL: "https://avatar.alles.cx/u/james", image: UIImage(systemName: "person.circle")!),
        Credit(name: "@DaThinkingChair", role: "Translator (Spanish)", url: "https://twitter.com/DaThinkingChair", imageURL: "https://pbs.twimg.com/profile_images/1259314332950769666/UPvu5g-e_400x400.jpg", image: UIImage(systemName: "person.circle")!),
        Credit(name: "Storm", role: "Translator (Norwegian)", url: "https://twitter.com/StormLovesTech", imageURL: "https://avatar.alles.cx/u/storm", image: UIImage(systemName: "person.circle")!),
        Credit(name: "primenate32", role: "Translator (Frensh, Spanish)", url: "http://123computer.net", imageURL: "https://pbs.twimg.com/profile_images/1288564622795182082/VduMZJzR_400x400.jpg", image: UIImage(systemName: "person.circle")!),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SLocale(.CREDITS)
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = CGFloat(70)
        tableView.register(CreditsCell.self, forCellReuseIdentifier: "creditsCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
        }
        // credits.sort(by: {$0.name < $1.name})
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "other")
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = toolbar
                titlebar.toolbarStyle = .automatic
            }

            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
        #endif

        DispatchQueue.global(qos: .utility).async {
            for (index, item) in self.credits.enumerated() {
                if let url = URL(string: item.imageURL) {
                    let image = ImageLoader.loadImageFromInternet(url: url)
                    self.credits[index].image = image
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: 0, section: index)], with: .automatic)
                    }
                }
            }
        }
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

extension CreditsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return credits.count
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == credits.count - 1 {
            return """
            Thank you to everyone that is helping developing this app!

            This also includes everyone who reports bugs, submits crash reports, makes suggestions!

            Thank you! <3


            """
        } else {
            return ""
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "creditsCell", for: indexPath) as! CreditsCell

        cell.creditUser = credits[indexPath.section]

        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let url = URL(string: credits[indexPath.section].url)
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }
}

struct Credit {
    var name: String
    var role: String
    var url: String
    var imageURL: String
    var image: UIImage
}

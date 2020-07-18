//
//  CreditsViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import UIKit

class CreditsViewController: UIViewController {
    var tableView: UITableView!

    var credits = [
        Credit(name: "Adrian", role: "iOS Developer", url: "https://twitter.com/adrianbaumgart", imageURL: "https://avatar.alles.cx/u/adrian", image: UIImage(systemName: "person.circle")!),
        Credit(name: "Patrik", role: "iOS Developer", url: "https://twitter.com/PatrikTheDev", imageURL: "https://pbs.twimg.com/profile_images/1257940562801577984/eWJ4Sp-i_400x400.jpg", image: UIImage(systemName: "person.circle")!),
        Credit(name: "Archie", role: "Alles Founder", url: "https://twitter.com/onlytruearchie", imageURL: "https://avatar.alles.cx/u/archie", image: UIImage(systemName: "person.circle")!),
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
            make.leading.equalTo(view.snp.leading)
            make.bottom.equalTo(view.snp.bottom)
            make.trailing.equalTo(view.snp.trailing)
        }
        // credits.sort(by: {$0.name < $1.name})
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_: Bool) {
        DispatchQueue.global(qos: .utility).async {
            for (index, item) in self.credits.enumerated() {
                let image = ImageLoader.loadImageFromInternet(url: URL(string: item.imageURL)!)
                self.credits[index].image = image
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: index)], with: .automatic)
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

            This also includes everyone who reports bugs, submits crash reports and makes suggestions!

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

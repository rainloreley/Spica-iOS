//
//  UsedLibrariesViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
//

import UIKit

class UsedLibrariesViewController: UIViewController {
	
	var libraries: [Library] = [
		Library(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire"),
		Library(name: "JGProgressHUD", url: "https://github.com/JonasGessner/JGProgressHUD"),
		Library(name: "SnapKit", url: "https://github.com/SnapKit/SnapKit"),
		Library(name: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON"),
		Library(name: "KMPlaceholderTextView", url: "https://github.com/MoZhouqi/KMPlaceholderTextView"),
		Library(name: "SPAlert", url: "https://github.com/ivanvorobei/SPAlert"),
		Library(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper")
	]
	
	var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = "Libraries"
		tableView = UITableView(frame: self.view.bounds, style: .insetGrouped)
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)
		libraries.sort(by: {$0.name < $1.name})

        // Do any additional setup after loading the view.
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

extension UsedLibrariesViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return libraries.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
		cell.textLabel?.text = libraries[indexPath.section].name
		cell.textLabel?.font = .boldSystemFont(ofSize: 20)
		cell.detailTextLabel?.text = libraries[indexPath.section].url
		cell.detailTextLabel?.textColor = .secondaryLabel
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let url = URL(string: libraries[indexPath.section].url)
		if UIApplication.shared.canOpenURL(url!) {
			UIApplication.shared.open(url!)
		}
	}
	
	
}

struct Library {
	var name: String
	var url: String
}
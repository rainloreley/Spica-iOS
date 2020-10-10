//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftKeychainWrapper
import UIKit

class TabBarController: UITabBarController {
    private lazy var feedViewController = makeFeedViewController()
    private lazy var mentionViewController = makeMentionViewController()
    private lazy var accountViewController = makeAccountViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [feedViewController, mentionViewController, accountViewController]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedIndex = 0
    }

    func showViewController(_ vc: UIViewController) {
        if let navigationcontroller = viewControllers?[selectedIndex] as? UINavigationController {
            navigationcontroller.viewControllers.first?.dismiss(animated: true, completion: nil)
            vc.hidesBottomBarWhenPushed = true
            navigationcontroller.viewControllers.last?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

private extension TabBarController {
    private func makeFeedViewController() -> UINavigationController {
        let vc = FeedViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Feed",
                                     image: UIImage(systemName: "house"),
                                     tag: 0)
        return UINavigationController(rootViewController: vc)
    }

    private func makeMentionViewController() -> UINavigationController {
        let vc = MentionsViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Mentions",
                                     image: UIImage(systemName: "at"),
                                     tag: 1)
        return UINavigationController(rootViewController: vc)
    }

    private func makeAccountViewController() -> UINavigationController {
        let vc = UserProfileViewController(style: .insetGrouped)
        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        vc.user = User(id: id ?? "")
        vc.tabBarItem = UITabBarItem(title: "Account",
                                     image: UIImage(systemName: "person.circle"),
                                     tag: 2)
        return UINavigationController(rootViewController: vc)
    }
}

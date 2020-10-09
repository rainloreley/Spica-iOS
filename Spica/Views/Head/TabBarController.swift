//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class TabBarController: UITabBarController {
    private lazy var feedViewController = makeFeedViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [feedViewController]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedIndex = 0
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
}

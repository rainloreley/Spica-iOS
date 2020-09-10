//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.09.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class GlobalTabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func showVC(_ vc: UIViewController) {
        if let navigationcontroller = viewControllers?[selectedIndex] as? UINavigationController {
            navigationcontroller.viewControllers.first?.dismiss(animated: true, completion: nil)
            vc.hidesBottomBarWhenPushed = true
            navigationcontroller.viewControllers.last?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

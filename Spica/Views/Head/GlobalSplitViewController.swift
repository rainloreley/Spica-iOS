//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class GlobalSplitViewController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func showViewController(_ vc: UIViewController) {
        if let tabbar = viewControllers.first as? TabBarController {
            if let navigationcontroller = tabbar.viewControllers?[tabbar.selectedIndex] as? UINavigationController {
                navigationcontroller.viewControllers.first?.dismiss(animated: true, completion: nil)
                vc.hidesBottomBarWhenPushed = true
                navigationcontroller.viewControllers.last?.navigationController?.pushViewController(vc, animated: true)
            } else {
                print("UINavigationController error lvl 2")
            }
        } else {
            if let navigationcontroller = viewControllers.last as? UINavigationController {
                navigationcontroller.viewControllers.first?.dismiss(animated: true, completion: nil)
                vc.hidesBottomBarWhenPushed = true
                navigationcontroller.viewControllers.last?.navigationController?.pushViewController(vc, animated: true)
            } else {
                print("UINavigationController error lvl 1")
            }
        }
    }
}

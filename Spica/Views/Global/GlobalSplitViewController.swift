//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 15.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

@available(iOS 14.0, *)
class GlobalSplitViewController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override init(style: UISplitViewController.Style) {
        super.init(style: style)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showVC(_ vc: UIViewController) {
        if let tabbar = viewControllers.first as? GlobalTabBarViewController {
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

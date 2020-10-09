//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import UIKit

extension MicroAPI {
    public func errorHandling(error: MicroError, caller _: UIView) {
        EZAlertController.alert("Error", message: "The following error occurred:\n\(error.name)", buttons: ["Ok"]) { _, _ in

            if error.action != nil {
                if error.action!.starts(with: "nav:"), error.action!.components(separatedBy: ":").last == "login" {
                    // NAVIGATE TO LOGIN
                    /* let mySceneDelegate = caller.window!.windowScene!.delegate as! SceneDelegate
                     mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                     mySceneDelegate.window?.makeKeyAndVisible() */
                }
            }
        }
    }
}

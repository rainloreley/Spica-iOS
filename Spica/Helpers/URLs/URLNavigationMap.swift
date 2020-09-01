//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 29.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftKeychainWrapper
import URLNavigator
struct URLNavigationMap {
    static func initialize(navigator: Navigator, sceneDelegate: SceneDelegate) {
        navigator.register("spica://user/<string:id>") { _, values, _ in
            print("CALLED SCHEME")
            if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
                let initialView = sceneDelegate.setupInitialView()
                if #available(iOS 14.0, *) {
                    if let view = initialView as? GlobalSplitViewController {
                        let userDetail = UserProfileViewController()
                        guard let userID = values["id"] as? String else { return nil }
                        userDetail.user = User(id: userID)
                        view.showDetailViewController(userDetail, sender: nil)
                        print("IMMA RETURN YOU")
                        return userDetail
                    }
                }

                if let view = initialView as? UITabBarController {
                    let userDetail = UserProfileViewController()
                    guard let userID = values["id"] as? String else { return nil }
                    userDetail.user = User(id: userID)
                    view.showDetailViewController(userDetail, sender: nil)
                    return view
                }

                print("f in chat")

                return initialView

            } else {
                return UINavigationController(rootViewController: LoginViewController())
            }
        }
        /* navigator.register("spica://post/<string:id>") { url, values, context in

         } */
    }
}

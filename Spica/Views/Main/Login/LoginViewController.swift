//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftUI
import UIKit

class LoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginController = LoginController()
        loginController.delegate = self
        let swiftUIView = LoginView(controller: loginController)
        let hostingController = UIHostingController(rootView: swiftUIView)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.bottom.equalTo(view.snp.bottom)
        }
    }
}

extension LoginViewController: LoginViewDelegate {
    func loggedIn(token _: String) {
        let sceneDelegate = view.window!.windowScene!.delegate as! SceneDelegate

        let initialViewController = sceneDelegate.loadInitialViewController(checkLogin: false)

        sceneDelegate.window?.rootViewController = initialViewController
        sceneDelegate.window?.makeKeyAndVisible()
    }
}

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

var spicaAppSplitViewController: GlobalSplitViewController!
var spicaAppSidebarViewController: SidebarViewController!
var spicaAppTabbarViewController: TabBarController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options launchOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let initialViewController = loadInitialViewController()
            window.rootViewController = initialViewController
            self.window = window
            window.tintColor = UserDefaults.standard.colorForKey(key: "globalTintColor")

            URLNavigationMap.initialize(navigator: navigator, sceneDelegate: self)
            window.makeKeyAndVisible()

            if isUserLoggedIn() {
                if !launchOptions.urlContexts.isEmpty {
                    guard let url = launchOptions.urlContexts.first else { return }
                    guard let navigatorViewController = navigator.viewController(for: url.url) else { return }
                    showURLContextViewController(navigatorViewController)
                }
            }
        }
    }

    func loadInitialViewController(checkLogin: Bool = true) -> UIViewController {
        if !isUserLoggedIn(), checkLogin {
            return LoginViewController()
        } else {
            loadSplitViewController()
            return spicaAppSplitViewController
        }
    }

    func isUserLoggedIn() -> Bool {
        if !UserDefaults.standard.bool(forKey: "hasRunSpicav2") {
            KeychainWrapper.standard.removeAllKeys()
            UserDefaults.standard.set(true, forKey: "hasRunSpicav2")
        }

        return KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token") && KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id")
    }

    func loadSplitViewController() {
        spicaAppSplitViewController = GlobalSplitViewController(style: .doubleColumn)
        spicaAppSplitViewController.preferredDisplayMode = .oneBesideSecondary
        spicaAppSplitViewController.presentsWithGesture = false
        spicaAppSplitViewController.preferredSplitBehavior = .tile

        spicaAppSidebarViewController = SidebarViewController()
        spicaAppTabbarViewController = TabBarController()

        spicaAppSplitViewController.setViewController(spicaAppSidebarViewController, for: .primary)
        spicaAppSplitViewController.setViewController(spicaAppTabbarViewController, for: .compact)
    }

    func showURLContextViewController(_ controller: UIViewController) {
        if #available(iOS 14.0, *) {
            spicaAppSplitViewController.showViewController(controller)
        } else {
            spicaAppTabbarViewController.showViewController(controller)
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if isUserLoggedIn() {
            guard let url = URLContexts.first else { return }
            guard let navigatorViewController = navigator.viewController(for: url.url) else { return }
            showURLContextViewController(navigatorViewController)
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

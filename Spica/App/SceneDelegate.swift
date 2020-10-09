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

var spicaAppSplitViewController: UISplitViewController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            let initialViewController = loadInitialViewController()

            window.rootViewController = initialViewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func loadInitialViewController() -> UIViewController {
        loadSplitViewController()
        return spicaAppSplitViewController
    }

    func loadSplitViewController() {
        spicaAppSplitViewController = UISplitViewController(style: .doubleColumn)
        spicaAppSplitViewController.preferredDisplayMode = .oneBesideSecondary
        spicaAppSplitViewController.presentsWithGesture = false
        spicaAppSplitViewController.preferredSplitBehavior = .tile

        spicaAppSplitViewController.setViewController(SidebarViewController(), for: .primary)
        spicaAppSplitViewController.setViewController(TabBarController(), for: .compact)
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

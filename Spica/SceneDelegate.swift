//
//  SceneDelegate.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
var globalSplitViewController: GlobalSplitViewController!
@available(iOS 14.0, *)
var globalSideBarController: SidebarViewController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene

        // DEBUG: REMOVE KEY TO TEST LOGIN - DO NOT USE IN PRODUCTION
        /* KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username") */

        let tabBar = UITabBarController()

        let homeView = UINavigationController(rootViewController: TimelineViewController())
        homeView.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)

        let mentionView = UINavigationController(rootViewController: MentionsViewController())
        mentionView.tabBarItem = UITabBarItem(title: "Notifications", image: UIImage(systemName: "bell"), tag: 1)

        tabBar.viewControllers = [homeView, mentionView]

        if #available(iOS 14.0, *) {
            globalSplitViewController = GlobalSplitViewController(style: .doubleColumn)
            globalSideBarController = SidebarViewController()
            // splitViewController.presentsWithGesture = false
            globalSplitViewController.setViewController(globalSideBarController, for: .primary)
            globalSplitViewController.setViewController(TimelineViewController(), for: .secondary)
            globalSplitViewController.setViewController(tabBar, for: .compact)
            globalSplitViewController.primaryBackgroundStyle = .sidebar

            globalSplitViewController.navigationItem.largeTitleDisplayMode = .always

            #if targetEnvironment(macCatalyst)
                if let titlebar = windowScene.titlebar {
                    titlebar.titleVisibility = .hidden
                    titlebar.toolbar = nil
                }
            #endif

            window?.rootViewController = globalSplitViewController

        } else {
            window?.rootViewController = tabBar
        }

        if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
            window?.makeKeyAndVisible()
        } else {
            window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window?.makeKeyAndVisible()
        }

        _ = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendOnline), userInfo: nil, repeats: true)
    }

    @objc func sendOnline() {
        AllesAPI.default.sendOnlineStatus()
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

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

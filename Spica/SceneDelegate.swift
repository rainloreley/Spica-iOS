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
    var toolbarDelegate = ToolbarDelegate()

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene

        if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
        }

        KeychainWrapper.standard.set("000", forKey: "dev.abmgrt.spica.user.token")
        KeychainWrapper.standard.set("999", forKey: "dev.abmgrt.spica.user.id")
        KeychainWrapper.standard.set("adrian", forKey: "dev.abmgrt.spica.user.username")

        UserDefaults.standard.set(true, forKey: "hasRunBefore")

        // DEBUG: REMOVE KEY TO TEST LOGIN - DO NOT USE IN PRODUCTION
        /* KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username") */

        if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
            let initialView = setupInitialView()
            window?.rootViewController = initialView
            window?.makeKeyAndVisible()
        } else {
            window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window?.makeKeyAndVisible()
        }

        _ = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendOnline), userInfo: nil, repeats: true)
    }

    func setupTabView() -> UITabBarController {
        let tabBar = UITabBarController()
        let homeView = UINavigationController(rootViewController: TimelineViewController())
        homeView.tabBarItem = UITabBarItem(title: SLocale(.HOME), image: UIImage(systemName: "house"), tag: 0)
        let mentionView = UINavigationController(rootViewController: MentionsViewController())
        mentionView.tabBarItem = UITabBarItem(title: SLocale(.NOTIFICATIONS), image: UIImage(systemName: "bell"), tag: 1)
        let bookmarksView = UINavigationController(rootViewController: BookmarksViewController())
        bookmarksView.tabBarItem = UITabBarItem(title: SLocale(.BOOKMARKS), image: UIImage(systemName: "bookmark"), tag: 2)

        let userProfileVC = UserProfileViewController()
        let username = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")

        userProfileVC.user = User(name: username!, nickname: username!)

        let accountView = UINavigationController(rootViewController: userProfileVC)
        accountView.tabBarItem = UITabBarItem(title: SLocale(.ACCOUNT), image: UIImage(systemName: "person"), tag: 3)
        tabBar.viewControllers = [homeView, mentionView, bookmarksView, accountView]
        return tabBar
    }

    func setupInitialView() -> UIViewController? {
        if #available(iOS 14.0, *) {
            let tabBar = setupTabView()
            globalSplitViewController = GlobalSplitViewController(style: .doubleColumn)
            globalSideBarController = SidebarViewController()
            globalSplitViewController.setViewController(globalSideBarController, for: .primary)
            globalSplitViewController.setViewController(TimelineViewController(), for: .secondary)
            globalSplitViewController.setViewController(tabBar, for: .compact)
            globalSplitViewController.primaryBackgroundStyle = .sidebar

            globalSplitViewController.navigationItem.largeTitleDisplayMode = .always
            return globalSplitViewController
        } else {
            let tabBar = setupTabView()
            return tabBar
        }
    }

    @objc func sendOnline() {
        AllesAPI.default.sendOnlineStatus()
    }

    func sceneDidDisconnect(_: UIScene) {}

    func sceneDidBecomeActive(_: UIScene) {}

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {}

    func sceneDidEnterBackground(_: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

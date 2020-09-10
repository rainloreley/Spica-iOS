//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 29.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftKeychainWrapper
import SwiftUI
import UIKit

@available(iOS 14.0, *)
var globalSplitViewController: GlobalSplitViewController!
@available(iOS 14.0, *)
var globalSideBarController: SidebarViewController!

var globalTabBarController: GlobalTabBarViewController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var toolbarDelegate = ToolbarDelegate()

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options launchOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.tintColor = UserDefaults.standard.colorForKey(key: "globalTintColor")

        URLNavigationMap.initialize(navigator: navigator, sceneDelegate: self)

        if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.name")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.tag")
            UserDefaults.standard.set(true, forKey: "hasRunBefore")
        }

        if !UserDefaults.standard.bool(forKey: "hasRunOnNewAPI") {
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.name")
            KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.tag")
            UserDefaults.standard.set(true, forKey: "hasRunOnNewAPI")
        }

        // DEBUG: REMOVE KEY TO TEST LOGIN - DO NOT USE IN PRODUCTION
        /* KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
         KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.username") */

        if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
            let initialView = setupInitialView()
            window?.rootViewController = initialView
            window?.makeKeyAndVisible()
            if !launchOptions.urlContexts.isEmpty {
                guard let url = launchOptions.urlContexts.first else { return }
                guard let newVC = navigator.viewController(for: url.url) else { return }

                if #available(iOS 14.0, *) {
                    globalSplitViewController.showVC(newVC)
                } else {
                    globalTabBarController.showVC(newVC)
                }
            }
        } else {
            window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
            window?.makeKeyAndVisible()
        }

        _ = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(sendOnline), userInfo: nil, repeats: true)
    }

    func setupTabView() -> GlobalTabBarViewController {
        let tabbar = GlobalTabBarViewController()
        let homeView = UINavigationController(rootViewController: TimelineViewController())
        homeView.tabBarItem = UITabBarItem(title: SLocale(.HOME), image: UIImage(systemName: "house"), tag: 0)
        let mentionView = UINavigationController(rootViewController: MentionsViewController())
        mentionView.tabBarItem = UITabBarItem(title: SLocale(.NOTIFICATIONS), image: UIImage(systemName: "bell"), tag: 1)
        let bookmarksView = UINavigationController(rootViewController: BookmarksViewController())
        bookmarksView.tabBarItem = UITabBarItem(title: SLocale(.BOOKMARKS), image: UIImage(systemName: "bookmark"), tag: 2)

        let userProfileVC = UserProfileViewController()
        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        let name = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name")
        let tag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag")

        userProfileVC.user = User(id: id!, name: name!, tag: tag!)

        let accountView = UINavigationController(rootViewController: userProfileVC)
        accountView.tabBarItem = UITabBarItem(title: SLocale(.ACCOUNT), image: UIImage(systemName: "person"), tag: 3)
        tabbar.viewControllers = [homeView, mentionView, bookmarksView, accountView]
        return tabbar
    }

    func setupInitialView() -> UIViewController? {
        if #available(iOS 14.0, *) {
            globalTabBarController = setupTabView()
            globalSplitViewController = GlobalSplitViewController(style: .doubleColumn)
            globalSideBarController = SidebarViewController()
            globalSplitViewController.setViewController(globalSideBarController, for: .primary)
            globalSplitViewController.setViewController(TimelineViewController(), for: .secondary)
            globalSplitViewController.setViewController(globalTabBarController, for: .compact)
            globalSplitViewController.primaryBackgroundStyle = .sidebar

            globalSplitViewController.navigationItem.largeTitleDisplayMode = .always
            return globalSplitViewController
        } else {
            globalTabBarController = setupTabView()
            return globalTabBarController
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token"), KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
            guard let url = URLContexts.first else { return }
            guard let newVC = navigator.viewController(for: url.url) else { return }

            if #available(iOS 14.0, *) {
                globalSplitViewController.showVC(newVC)
            } else {
                globalTabBarController.showVC(newVC)
            }
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

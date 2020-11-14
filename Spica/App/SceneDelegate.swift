//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Kingfisher
import LocalAuthentication
import SwiftKeychainWrapper
import UIKit

@available(iOS 14.0, *)
var spicaAppSplitViewController: GlobalSplitViewController!
@available(iOS 14.0, *)
var spicaAppSidebarViewController: SidebarViewController!

var spicaAppTabbarViewController: TabBarController!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var sessionAuthorized: Bool = false

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options launchOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let initialViewController = loadInitialViewController()
            window.rootViewController = initialViewController
            self.window = window
            window.tintColor = UserDefaults.standard.colorForKey(key: "globalTintColor")

            URLNavigationMap.initialize(navigator: navigator, sceneDelegate: self)
            window.makeKeyAndVisible()
            verifyBiometricAuthentication()
            Kingfisher.ImageCache.default.diskStorage.config.expiration = .days(1)

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
            if #available(iOS 14.0, *) {
                loadSplitViewController()
                return spicaAppSplitViewController
            } else {
                loadTabBar()
                return spicaAppTabbarViewController
            }
        }
    }

    func isUserLoggedIn() -> Bool {
        if !UserDefaults.standard.bool(forKey: "hasRunSpicav2") {
            KeychainWrapper.standard.removeAllKeys()
            UserDefaults.standard.set(true, forKey: "hasRunSpicav2")
        }

        return KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token") && KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id")
    }

    @available(iOS 14.0, *)
    func loadSplitViewController() {
        spicaAppSplitViewController = GlobalSplitViewController(style: .doubleColumn)
        spicaAppSplitViewController.preferredDisplayMode = .oneBesideSecondary
        spicaAppSplitViewController.presentsWithGesture = true
        spicaAppSplitViewController.preferredSplitBehavior = .tile
        spicaAppSplitViewController.primaryBackgroundStyle = .sidebar

        spicaAppSidebarViewController = SidebarViewController()
        loadTabBar()

		spicaAppSplitViewController.setViewController(spicaAppSidebarViewController, for: .primary)
        spicaAppSplitViewController.setViewController(spicaAppTabbarViewController, for: .compact)
    }

    func loadTabBar() {
        spicaAppTabbarViewController = TabBarController()
    }

    func showURLContextViewController(_ controller: UIViewController) {
        if #available(iOS 14.0, *) {
            spicaAppSplitViewController.showViewController(controller)
        } else {
            spicaAppTabbarViewController.showViewController(controller)
        }
    }

    func verifyBiometricAuthentication() {
        if UserDefaults.standard.bool(forKey: "biometricAuthEnabled"), sessionAuthorized == false {
            let rootView = window?.rootViewController
            let blurStyle = rootView!.traitCollection.userInterfaceStyle == .dark ? UIBlurEffect.Style.dark : UIBlurEffect.Style.light
            let blurEffect = UIBlurEffect(style: blurStyle)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = (rootView?.view.bounds)!
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurEffectView.alpha = 1.0
            blurEffectView.tag = 395
            if rootView?.view.viewWithTag(395) != nil {
                //
            } else {
                rootView?.view.addSubview(blurEffectView)
                blurEffectView.snp.makeConstraints { make in
                    make.top.equalTo(rootView!.view.snp.top)
                    make.leading.equalTo(rootView!.view.snp.leading)
                    make.bottom.equalTo(rootView!.view.snp.bottom)
                    make.trailing.equalTo(rootView!.view.snp.trailing)
                }
            }

            let authContext = LAContext()
            var authError: NSError?
            if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Spica") { success, _ in
                    if success {
                        DispatchQueue.main.async { [self] in
                            sessionAuthorized = true
                            UIView.animate(withDuration: 0.2, animations: {
                                blurEffectView.alpha = 0.0
							}) { _ in
                                if let blurTag = rootView?.view.viewWithTag(395) {
                                    blurTag.removeFromSuperview()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            EZAlertController.alert("Biometric authentication failed", message: "Plase try again", acceptMessage: "Retry") {
                                self.verifyBiometricAuthentication()
                            }
                        }
                    }
                }
            } else {
                var type = "FaceID / TouchID"
                let biometric = biometricType()
                switch biometric {
                case .face:
                    type = "FaceID"
                case .touch:
                    type = "TouchID"
                case .none:
                    type = "FaceID / TouchID"
                }
                EZAlertController.alert("Device error", message: "\(type) is not enrolled on your device. Please verify it's enabled in your devices' settings", actions: [UIAlertAction(title: "Retry", style: .default, handler: { _ in
                    self.verifyBiometricAuthentication()
				})])
            }
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

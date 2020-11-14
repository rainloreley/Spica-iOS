//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit
import URLNavigator
import UserNotifications
import SwiftKeychainWrapper
import SwiftyJSON

let navigator = Navigator()

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
		if KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.token") && KeychainWrapper.standard.hasValue(forKey: "dev.abmgrt.spica.user.id") {
			registerForPushNotifications()
			getNotificationSettings()
		}
		UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let userInfo = response.notification.request.content.userInfo
		UIApplication.shared.applicationIconBadgeNumber = 0
		guard let data = userInfo as? [String: AnyObject] else {
			completionHandler()
			return
		  }
		let payload = JSON(data)
		if payload["type"].exists() && payload["id"].exists() {
			if payload["type"].string! == "post" {
				UIApplication.shared.open(URL(string: "spica://post/\(payload["id"].string!)")!)
			}
			else {
				completionHandler()
			}
		}
		else {
			completionHandler()
		}
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		UIApplication.shared.applicationIconBadgeNumber = 0
		NotificationCenter.default.post(name: Notification.Name("loadMentionsCount"), object: nil)
		completionHandler(.alert)
	}
	
	func registerForPushNotifications() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
			UNUserNotificationCenter.current().delegate = self
			guard granted else { return }
			self.getNotificationSettings()
		}
	}
	
	func getNotificationSettings() {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			guard settings.authorizationStatus == .authorized else { return }
			DispatchQueue.main.async {
				UIApplication.shared.registerForRemoteNotifications()
			}
		}
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
		let token = tokenParts.joined()
		print("Registered for push notifications with token: \(token)")
		SpicaPushAPI.default.setDeviceTokenForSignedInUser(token) { (result) in
			switch result {
				case let .failure(err):
					print(err.error.name)
				default: break
			}
		}
	}
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("Failed to register for push notifications: \(error.localizedDescription)")
	}
	
	

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

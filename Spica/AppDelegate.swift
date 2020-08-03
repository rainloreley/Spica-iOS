//
//  AppDelegate.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import CoreData
import UIKit

let globalDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM dd, yyyy HH:mm", options: 0, locale: Locale.current) // "MMM dd, yyyy HH:mm"
    formatter.timeZone = TimeZone.current
    return formatter
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var sessionAuthorized = false

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Alles_App")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {}
	    })
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {}
        }
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftKeychainWrapper
import UIKit

class TabBarController: UITabBarController {
    private lazy var feedViewController = makeFeedViewController()
    private lazy var mentionViewController = makeMentionViewController()
    private lazy var bookmarksViewController = makeBookmarksViewController()
    private lazy var searchViewController = makeSearchViewController()
    private lazy var accountViewController = makeAccountViewController()

    var mentionsTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [feedViewController, mentionViewController, bookmarksViewController, searchViewController, accountViewController]
        selectedIndex = 0
        loadMentionsCount()
        mentionsTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(loadMentionsCount), userInfo: nil, repeats: true)
		NotificationCenter.default.addObserver(self, selector: #selector(loadMentionsCount), name: Notification.Name("loadMentionsCount"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc func loadMentionsCount() {
        MicroAPI.default.getUnreadMentions(allowError: false) { [self] result in
            switch result {
            case .failure:
                break
            case let .success(mentions):
                DispatchQueue.main.async {
                    if mentions.count > 0 {
                        mentionViewController.tabBarItem.badgeValue = "\(mentions.count)"
                    } else {
                        mentionViewController.tabBarItem.badgeValue = nil
                    }
                }
            }
        }
    }

    func showViewController(_ vc: UIViewController) {
        if let navigationcontroller = viewControllers?[selectedIndex] as? UINavigationController {
            navigationcontroller.viewControllers.first?.dismiss(animated: true, completion: nil)
            vc.hidesBottomBarWhenPushed = true
            navigationcontroller.viewControllers.last?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

private extension TabBarController {
    private func makeFeedViewController() -> UINavigationController {
        let vc = FeedViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Feed",
                                     image: UIImage(systemName: "house"),
                                     tag: 0)
        return UINavigationController(rootViewController: vc)
    }

    private func makeMentionViewController() -> UINavigationController {
        let vc = MentionsViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Mentions",
                                     image: UIImage(systemName: "at"),
                                     tag: 1)
        return UINavigationController(rootViewController: vc)
    }

    private func makeBookmarksViewController() -> UINavigationController {
        let vc = BookmarksViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Bookmarks",
                                     image: UIImage(systemName: "bookmark"),
                                     tag: 2)
        return UINavigationController(rootViewController: vc)
    }

    private func makeSearchViewController() -> UINavigationController {
        let vc = SearchViewController(style: .insetGrouped)
        vc.tabBarItem = UITabBarItem(title: "Search",
                                     image: UIImage(systemName: "magnifyingglass"),
                                     tag: 3)
        return UINavigationController(rootViewController: vc)
    }

    private func makeAccountViewController() -> UINavigationController {
        let vc = UserProfileViewController(style: .insetGrouped)
        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        vc.user = User(id: id ?? "")
        vc.tabBarItem = UITabBarItem(title: "Account",
                                     image: UIImage(systemName: "person.circle"),
                                     tag: 4)
        return UINavigationController(rootViewController: vc)
    }
}

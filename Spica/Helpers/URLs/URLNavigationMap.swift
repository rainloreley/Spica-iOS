//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 29.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftKeychainWrapper
import URLNavigator
struct URLNavigationMap {
    static func initialize(navigator: Navigator, sceneDelegate _: SceneDelegate) {
        navigator.register("spica://user/<string:id>") { _, values, _ in
            let userDetail = UserProfileViewController()
            guard let userID = values["id"] as? String else { return nil }
            userDetail.user = User(id: userID)
            return userDetail
        }

        navigator.register("spica://lol") { _, _, _ in
            let goURL = URL(string: "https://go.abmgrt.dev/lyWKrc")!
            if UIApplication.shared.canOpenURL(goURL) {
                UIApplication.shared.open(goURL)
            }
            return nil
        }

        navigator.register("spica://post/<string:id>") { _, values, _ in
            let postDetail = PostDetailViewController()
            guard let postID = values["id"] as? String else { return nil }
            postDetail.selectedPostID = postID
            return postDetail
        }
		
		navigator.register("spica://tag/<string:name>") { _, values, _ in
			let tagDetail = TagDetailViewController()
			guard let tagName = values["name"] as? String else { return nil }
			tagDetail.tag = Tag(name: tagName, posts: [])
			return tagDetail
		}
    }
}

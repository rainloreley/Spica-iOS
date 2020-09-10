//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 22.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

public struct Tag {
    var name: String
    var posts: [Post]

    init(name: String, posts: [Post]) {
        self.name = name
        self.posts = posts
    }
}

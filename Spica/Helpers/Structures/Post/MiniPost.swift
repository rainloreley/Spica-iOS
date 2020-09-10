//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 01.09.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

struct MiniPost: Hashable {
    var id: String
    var author: User?
    var content: String

    init(id: String = "", author: User? = nil, content: String = "") {
        self.id = id == "" ? randomString(length: 30) : id
        self.author = author
        self.content = content
    }

    init(_ post: Post) {
        id = post.id
        author = post.author
        content = post.content
    }
}

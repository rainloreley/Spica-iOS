//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 25.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

struct Bookmark: Hashable, Codable {
    var id: String!
    var added: Date!

    init(id: String, added: Date) {
        self.id = id
        self.added = added
    }
}

struct AdvancedBookmark: Hashable {
    var bookmark: Bookmark
    var post: Post

    init(bookmark: Bookmark, post: Post) {
        self.bookmark = bookmark
        self.post = post
    }
}

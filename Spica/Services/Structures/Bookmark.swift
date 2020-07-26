//
//  Bookmark.swift
//  Spica
//
//  Created by Adrian Baumgart on 25.07.20.
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

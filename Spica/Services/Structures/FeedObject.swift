//
//  FeedObject.swift
//  Spica
//
//  Created by Adrian Baumgart on 22.07.20.
//

import Foundation
import Unrealm

public struct FeedObject: Realmable {
    public init() {
        id = ""
        isCached = false
        post = nil
    }

    var id: String = ""
    var isCached = false
    var post: Post?

    init(id: String, isCached: Bool, post: Post) {
        self.id = id
        self.isCached = isCached
        self.post = post
    }
}

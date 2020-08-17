//
//  Notification.swift
//  Spica
//
//  Created by Adrian Baumgart on 15.08.20.
//

import Foundation

public struct PostNotification: Hashable {
    var post: Post
    var read: Bool

    init(post: Post, read: Bool = true) {
        self.post = post
        self.read = read
    }
}

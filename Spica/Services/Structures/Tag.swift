//
//  Tag.swift
//  Spica
//
//  Created by Adrian Baumgart on 22.07.20.
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

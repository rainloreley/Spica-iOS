//
//  Post.swift
//  Spica
//
//  Created by Adrian Baumgart on 12.08.20.
//

import Foundation
import SwiftyJSON
import UIKit

public struct Post: Hashable {
    var id: String
    var author: User?
    var author_id: String
    var parent_id: String?
    var children_ids: [String]
    var children_count: Int
    var content: String
    var imageURL: URL?
    var image: UIImage?
    var score: Int
    var voted: Int
    var created: Date
    var interactions: Int?

    var mentionedUsers: [User]

    init(id: String = "", author: User? = nil, author_id: String = "", parent_id: String? = nil, children_ids: [String] = [], children_count: Int = 0, content: String = "", imageURL: URL? = nil, image: UIImage? = nil, score: Int = 0, voted: Int = 0, created: Date = Date(), mentionedUsers: [User] = [], interactions: Int? = nil) {
        self.id = id == "" ? randomString(length: 30) : id
        self.author = author
        self.author_id = author_id == "" ? randomString(length: 30) : author_id
        self.parent_id = parent_id
        self.children_ids = children_ids
        self.children_count = children_count
        self.content = content
        self.imageURL = imageURL
        self.image = image
        self.score = score
        self.voted = voted
        self.created = created
        self.mentionedUsers = mentionedUsers
        self.interactions = interactions
    }

    init(_ json: JSON, mentionedUsers: [User]) {
        id = json["id"].string ?? randomString(length: 30)
        author = nil
        author_id = json["author"].string ?? randomString(length: 30)
        parent_id = json["parent"].string ?? nil
        children_ids = json["children"]["list"].arrayValue.map { $0.stringValue }
        children_count = json["children"]["count"].int ?? 0
        content = json["content"].string ?? ""
        if let urlStr = json["image"].string {
            imageURL = URL(string: "https://fs.alles.cx/\(urlStr)")
        } else {
            imageURL = nil
        }
        image = nil
        score = json["vote"]["score"].int ?? 0
        voted = json["vote"]["me"].int ?? 0
        created = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
        self.mentionedUsers = mentionedUsers
        interactions = json["interactions"].int ?? nil
    }
}

extension Post {
    static let deleted = Post(author: User(name: "---", nickname: "---"), content: "Post was deleted")
}

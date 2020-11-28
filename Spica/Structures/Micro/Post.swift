//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import Kingfisher
import SwiftyJSON
import UIKit

struct Post {
    var id: String
    var author: User
    var parent: String?
    var children: [String]
    var content: String
    var imageurl: URL?
    var image: KFCrossPlatformImage?
    var url: URL?
    var score: Int
    var vote: Int
    var interactions: Int?
    var createdAt: Date
    var mentionedUsers: [User]
    var isDeleted: Bool
    var containsRickroll: Bool

    init(id: String = "", author: User = User(), parent: String? = nil, children: [String] = [], content: String = "", imageurl: URL? = nil, image: UIImage? = nil, url: URL? = nil, score: Int = 0, vote: Int = 0, interactions: Int? = nil, createdAt: Date = Date(), mentionedUsers: [User] = [], isDeleted: Bool = false, containsRickroll: Bool = false) {
        self.id = id
        self.author = author
        self.parent = parent
        self.children = children
        self.content = content
        self.imageurl = imageurl
        self.image = image
        self.url = url
        self.score = score
        self.vote = vote
        self.interactions = interactions
        self.createdAt = createdAt
        self.mentionedUsers = mentionedUsers
        self.isDeleted = isDeleted
        self.containsRickroll = containsRickroll
    }

    init(_ json: JSON) {
        id = json["id"].string!
        author = User(json["author"])
        parent = json["parent"].string ?? nil
        children = json["children"]["list"].arrayValue.map { $0.stringValue }
        content = json["content"].string ?? ""
        imageurl = json["image"].string != nil ? URL(string: "https://walnut1.alles.cc/\(json["image"].string!)") : nil
        image = nil
        url = json["url"].string != nil ? URL(string: json["url"].string!) : nil
        score = json["vote"]["score"].int ?? 0
        vote = json["vote"]["me"].int ?? 0
        interactions = json["interactions"].int ?? nil
        createdAt = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
        mentionedUsers = []
        isDeleted = false
        containsRickroll = false
    }

    static var sample = Post(id: "sample", author: User.sample, parent: nil, children: [], content: "content", imageurl: URL(string: "https://avatar.alles.cx/87cd0529-f41b-4075-a002-059bf2311ce7"), image: nil, url: nil, score: 0, vote: 1, interactions: 3, createdAt: Date().addingTimeInterval(-60), mentionedUsers: [])

    static var deleted = Post(id: randomString(length: 20), author: User.deleted, parent: nil, children: [], content: "*deleted*", imageurl: nil, image: nil, score: 0, vote: 0, interactions: 0, createdAt: Date(timeIntervalSince1970: .zero), isDeleted: true)
}

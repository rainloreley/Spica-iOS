//
//  Post.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Cache
import Foundation
import SwiftyJSON
import UIKit

public struct OldPost: Hashable {
    var id: String
    var author: User?
    var date: Date
    var repliesCount: Int
    var score: Int
    var content: String
    var image: UIImage?
    var imageURL: URL?
    var voteStatus: Int

    public init(id: String, author: User, date: Date, repliesCount: Int, score: Int, content: String, image: UIImage? = nil, imageURL: URL? = nil, voteStatus: Int) {
        self.id = id
        self.author = author
        self.date = date
        self.repliesCount = repliesCount
        self.score = score
        self.content = content
        self.image = image
        self.imageURL = imageURL
        self.voteStatus = voteStatus
    }

    public static func empty(id: String = "", author: User, date: Date = Date(), repliesCount: Int = 0, score: Int = 0, content: String = "", image: UIImage? = nil, imageURL: URL? = nil, voteStatus: Int = 0) -> OldPost {
        return OldPost(id: id == "" ? randomString(length: 30) : id, author: author, date: date, repliesCount: repliesCount, score: score, content: content, image: image, imageURL: imageURL, voteStatus: voteStatus)
    }

    public init(_ json: JSON) {
        id = json["slug"].string!
        author = User(json["author"], isOnline: false)
        date = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
        repliesCount = json["replyCount"].intValue
        score = json["score"].int ?? 0
        content = json["content"].string!
        if let imageURLString = json["image"].string {
            imageURL = URL(string: imageURLString)
        }

        voteStatus = json["vote"].int ?? 0
    }
}

extension OldPost {
    static let deleted = OldPost.empty(author: User(name: "---", nickname: "---"), content: "Post was deleted")
}

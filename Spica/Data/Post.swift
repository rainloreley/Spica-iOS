//
//  Post.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Foundation
import UIKit
import SwiftyJSON

public struct Post: Hashable {
    var id: String
    var author: User
    var date: Date
    var repliesCount: Int
    var score: Int
    var content: String
    var image: UIImage?
    var imageURL: URL?
    var voteStatus: Int
    
    init(id: String, author: User, date: Date, repliesCount: Int, score: Int, content: String, image: UIImage? = nil, imageURL: URL? = nil, voteStatus: Int) {
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
    init(_ json: JSON) {
        id = json["slug"].string!
        author = User(id: json["author"]["id"].string!,
                      username: json["author"]["username"].string!,
                      displayName: json["author"]["name"].string!,
                      imageURL: URL(string: "https://avatar.alles.cx/u/\(json["author"]["username"])")!,
                      isPlus: json["author"]["plus"].bool ?? false,
                      rubies: 0,
                      followers: 0,
                      image: UIImage(systemName: "person.circle"),
                      isFollowing: false,
                      followsMe: false,
                      about: "",
                      isOnline: false)
        date = Date.dateFromISOString(string: json["json"].string ?? "") ?? Date()
        repliesCount = json["replyCount"].intValue
        score = json["score"].int ?? 0
        content = json["content"].string!
        if let imageURLString = json["image"].string {
            imageURL = URL(string: imageURLString)
        }
        voteStatus = json["vote"].int ?? 0
    }
}


extension Post {
    static let deleted = Post(id: "removed",
                              author: User(id: "---", username: "---", displayName: "---", imageURL: URL(string: "https://avatar.alles.cx/u/000000000000000000000000000000000000000")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false),
                              date: Date(),
                              repliesCount: 0,
                              score: 0,
                              content: "Post was deleted",
                              imageURL: nil,
                              voteStatus: 0)
}

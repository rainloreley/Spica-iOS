//
//  User.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Cache
import Foundation
import SwiftyJSON
import UIKit

public struct OldUser: Hashable {
    var id: String
    var username: String
    var displayName: String
    var nickname: String

    var isPlus: Bool
    var rubies: Int
    var followers: Int
    var imageURL: URL
    var image: UIImage?
    var isFollowing: Bool
    var followsMe: Bool
    var about: String
    var isOnline: Bool

    init(id: String, username: String, displayName: String, nickname: String, imageURL: URL, isPlus: Bool, rubies: Int, followers: Int, image: UIImage, isFollowing: Bool, followsMe: Bool, about: String, isOnline: Bool) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.nickname = nickname
        self.imageURL = imageURL
        self.isPlus = isPlus
        self.rubies = rubies
        self.followers = followers
        self.image = image
        self.isFollowing = isFollowing
        self.followsMe = followsMe
        self.about = about
        self.isOnline = isOnline
    }

    public static func empty(id: String = "", username: String = "", displayName: String = "", nickname: String = "", imageURL: URL = URL(string: "https://avatar.alles.cx/u/....")!, isPlus: Bool = false, rubies: Int = 0, followers: Int = 0, image: UIImage = UIImage(systemName: "person.circle")!, isFollowing: Bool = false, followsMe: Bool = false, about: String = "", isOnline: Bool = false) -> OldUser {
        return OldUser(id: id == "" ? randomString(length: 30) : id, username: username, displayName: displayName, nickname: nickname, imageURL: (username == "" ? imageURL : URL(string: "https://avatar.alles.cx/u/\(username)"))!, isPlus: isPlus, rubies: rubies, followers: followers, image: image, isFollowing: isFollowing, followsMe: followsMe, about: about, isOnline: isOnline)
    }

    init(_ json: JSON, isOnline: Bool) {
        id = json["id"].string!
        username = json["username"].string!
        displayName = json["name"].string!
        nickname = json["nickname"].string ?? json["name"].string!
        imageURL = URL(string: "https://avatar.alles.cx/u/\(json["username"])")!
        isPlus = json["plus"].bool ?? false
        rubies = json["rubies"].int ?? 0
        followers = json["followers"].int ?? 0

        image = UIImage(systemName: "person.circle")
        isFollowing = json["following"].bool ?? false
        followsMe = json["followingUser"].bool ?? false
        about = json["about"].string ?? ""
        self.isOnline = isOnline
    }
}

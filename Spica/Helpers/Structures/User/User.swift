//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON
import UIKit

public struct User: Hashable {
    var id: String
    var name: String
    var tag: String
    var nickname: String
    var plus: Bool
    var alles: Bool

    var image: UIImage?
    var imgURL: URL?

    var xp: XP
    var about: String
    var isFollowing: Bool
    var followsMe: Bool
    var isOnline: Bool
    var followers: Int
    var following: Int

    var joined: Date
    var postsCount: Int
    var repliesCount: Int
    var labels: [Label]

    init(id: String = "", name: String = "", tag: String = "", nickname: String = "", plus: Bool = false, alles: Bool = true, image: UIImage? = nil, imgURL: URL? = nil, xp: XP = XP(total: 0, level: 0, levelXP: 0, levelXPMax: 0, levelProgress: 0), about: String = "", isFollowing: Bool = false, followsMe: Bool = false, isOnline: Bool = false, followers: Int = 0, following: Int = 0, joined: Date = Date(), postsCount: Int = 0, repliesCount: Int = 0, labels: [Label] = []) {
        self.id = id == "" ? randomString(length: 20) : id
        self.name = name
        self.tag = tag
        self.nickname = nickname == "" ? name : nickname
        self.plus = plus
        self.alles = alles
        self.image = image == nil ? UIImage(systemName: "person.cirlce") : image
        self.imgURL = imgURL == nil ? URL(string: "https://avatar.alles.cc/\(id)") : imgURL
        self.xp = xp
        self.about = about
        self.isFollowing = isFollowing
        self.followsMe = followsMe
        self.isOnline = isOnline
        self.followers = followers
        self.following = following
        self.joined = joined
        self.postsCount = postsCount
        self.repliesCount = repliesCount
        self.labels = labels
    }

    init(_ json: JSON, isOnline: Bool = false) {
        id = json["id"].string ?? randomString(length: 20)
        name = json["name"].string ?? ""
        tag = json["tag"].string ?? ""
        nickname = json["nickname"].string ?? json["name"].string ?? ""
        plus = json["plus"].bool ?? false
        alles = json["alles"].bool ?? false
        image = UIImage(systemName: "person.cirlce")
        imgURL = URL(string: json["avatar"].string != nil ? "https://fs.alles.cx/\(json["avatar"].string!)" : "https://avatar.alles.cc/\(json["id"].string!)")
        // imgURL = URL(string: "https://fs.alles.cx/\(json["avatar"].string)" ?? "https://avatar.alles.cc/\(json["id"].string ?? "")")
        xp = XP(total: json["xp"]["total"].int ?? 020, level: json["xp"]["level"].int ?? 0, levelXP: json["xp"]["levelXp"].int ?? 0, levelXPMax: json["xp"]["levelXpMax"].int ?? 0, levelProgress: json["xp"]["levelProgress"].float ?? 0)
        about = json["about"].string ?? ""
        isFollowing = json["followers"]["me"].bool ?? false
        followsMe = json["following"]["me"].bool ?? false
        self.isOnline = isOnline
        followers = json["followers"]["count"].int ?? 0
        following = json["following"]["count"].int ?? 0
        joined = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
        postsCount = json["posts"]["count"].int ?? 0
        repliesCount = json["posts"]["replies"].int ?? 0
        labels = []
    }
}

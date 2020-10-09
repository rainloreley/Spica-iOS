//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON
import UIKit

struct User {
    var id: String
    var name: String
    var tag: String
    var plus: Bool
    var nickname: String
    var profilePicture: UIImage?
    var profilePictureUrl: URL
    var createdAt: Date
    var xp: XP

    var followercount: Int
    var iamFollowing: Bool

    var followingcount: Int
    var isFollowingMe: Bool
	
	var postsCount: Int
	var repliesCount: Int

	init(id: String = "", name: String = "", tag: String = "", plus: Bool = false, nickname: String = "", profilePicture: UIImage? = nil, profilePictureUrl: URL? = nil, createdAt: Date = Date(), xp: XP = XP(), followercount: Int = 0, iamFollowing: Bool = false, followingcount: Int = 0, isFollowingMe: Bool = false, postsCount: Int = 0, repliesCount: Int = 0) {
        self.id = id
        self.name = name
        self.tag = tag
        self.plus = plus
        self.nickname = nickname != "" ? nickname : name
        self.profilePicture = profilePicture
        self.profilePictureUrl = (profilePictureUrl != nil ? profilePictureUrl : URL(string: "https://avatar.alles.cc/\(id)"))!
        self.createdAt = createdAt
        self.xp = xp
        self.followercount = followercount
        self.iamFollowing = iamFollowing
        self.followingcount = followingcount
        self.isFollowingMe = isFollowingMe
		self.postsCount = postsCount
		self.repliesCount = repliesCount
    }

    init(_ json: JSON) {
        id = json["id"].string ?? ""
        name = json["name"].string ?? ""
        tag = json["tag"].string ?? ""
        plus = json["plus"].bool ?? false
        nickname = json["nickname"].string ?? json["name"].string ?? ""
        profilePicture = nil
        profilePictureUrl = URL(string: "https://avatar.alles.cc/\(json["id"].string ?? String("_"))")!
		createdAt = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
        
        xp = XP(json["xp"])
        followercount = json["followers"]["count"].int ?? 0
        iamFollowing = json["followers"]["me"].bool ?? false
        followingcount = json["following"]["count"].int ?? 0
        isFollowingMe = json["following"]["me"].bool ?? false
		postsCount = json["posts"]["count"].int ?? 0
		repliesCount = json["posts"]["replies"].int ?? 0
    }

    static var sample = User(id: "87cd0529-f41b-4075-a002-059bf2311ce7", name: "Lea", tag: "0001", plus: true, nickname: "Lea", profilePicture: UIImage(named: "leapfp"), createdAt: Date(), xp: XP(), followercount: 100, iamFollowing: true, followingcount: 69, isFollowingMe: true)
}

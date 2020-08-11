//
//  User.swift
//  Spica
//
//  Created by Adrian Baumgart on 11.08.20.
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
	var following: Bool
	var followsMe: Bool
	var isOnline: Bool
	var followers: Int
	
	
	init(id: String = "", name: String = "", tag: String = "", nickname: String = "", plus: Bool = false, alles: Bool = true, image: UIImage? = nil, imgURL: URL? = nil, xp: XP = XP(total: 0, level: 0, levelXP: 0, levelXPMax: 0, levelProgress: 0), about: String = "", following: Bool = false, followsMe: Bool = false, isOnline: Bool = false, followers: Int = 0) {
		self.id = id == "" ? randomString(length: 20) : id
		self.name = name
		self.tag = tag
		self.nickname = nickname == "" ? name : nickname
		self.plus = plus
		self.alles = alles
		self.image = image == nil ? UIImage(systemName: "person.cirlce") : image
		self.imgURL = imgURL == nil ? URL(string: "https://avarar.alles.cc/\(id)") : imgURL
		self.xp = xp
		self.about = about
		self.following = following
		self.followsMe = followsMe
		self.isOnline = isOnline
		self.followers = followers
	}
	
	init(_ json: JSON, isOnline: Bool = false) {
		self.id = json["id"].string ?? randomString(length: 20)
		self.name = json["name"].string ?? ""
		self.tag = json["tag"].string ?? ""
		self.nickname = json["nickname"].string ?? ""
		self.plus = json["plus"].bool ?? false
		self.alles = json["alles"].bool ?? false
		self.image = UIImage(systemName: "person.cirlce")
		self.imgURL = URL(string: "https://avatar.alles.cc\(json["id"].string ?? "")")
		self.xp = XP(total: json["xp"]["total"].int ?? 0, level: json["xp"]["level"].int ?? 0, levelXP: json["xp"]["levelXp"].int ?? 0, levelXPMax: json["xp"]["levelXpMax"].int ?? 0, levelProgress: json["xp"]["levelProgress"].float ?? 0)
		self.about = json["about"].string ?? ""
		self.following = json["following"].bool ?? false
		self.followsMe = json["followingUser"].bool ?? false
		self.isOnline = isOnline
		self.followers = json["followers"].int ?? 0
		
	}
	
	
	
	
}

//
//  FollowUser.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import Foundation
import UIKit
import SwiftyJSON

public struct FollowUser: Hashable {
	var id: String
	var username: String
	var name: String
	var isPlus: Bool
	var image: UIImage?
	var imageURL: URL
	
	init(id: String, username: String, name: String, isPlus: Bool, image: UIImage, imageURL: URL) {
		self.id = id
		self.username = username
		self.name = name
		self.isPlus = isPlus
		self.image = image
		self.imageURL = imageURL
	}
	
	init(_ json: JSON) {
		self.id = json["id"].string!
		self.username = json["username"].string!
		self.name = json["name"].string!
		self.isPlus = json["plus"].bool!
		self.image = UIImage(systemName: "person.circle")
		self.imageURL = URL(string: "https://avatar.alles.cx/u/\(json["username"])")!
	}
}

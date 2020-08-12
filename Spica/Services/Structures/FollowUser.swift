//
//  FollowUser.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import Foundation
import SwiftyJSON
import UIKit

public struct FollowUser: Hashable {
    var id: String
    var name: String
    var nickname: String
    var tag: String
    var isPlus: Bool
    var image: UIImage?
    var imageURL: URL

    init(id: String, name: String, nickname: String, tag: String, isPlus: Bool, image: UIImage, imageURL: URL) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.tag = tag
        self.isPlus = isPlus
        self.image = image
        self.imageURL = imageURL
    }

    init(_ json: JSON) {
        id = json["id"].string!
        name = json["name"].string!
        nickname = json["nickname"].string!
        tag = json["tag"].string!
        isPlus = json["plus"].bool!
        image = UIImage(systemName: "person.circle")
        imageURL = URL(string: "https://avatar.alles.cc/\(json["id"])")!
    }
}

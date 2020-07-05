//
//  User.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Foundation
import UIKit

public struct User {
    var id: String
    var username: String
    var displayName: String
    var imageURL: URL
    var isPlus: Bool
    var rubies: Int
    var followers: Int
    var image: UIImage
    var isFollowing: Bool
    var followsMe: Bool
    var about: String
	var isOnline: Bool
}

//
//  Post.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Foundation
import UIKit

public struct Post {
    var id: String
    var author: User
    var date: Date
    var repliesCount: Int
    var score: Int
    var content: String
    var image: UIImage?
    var voteStatus: Int
}

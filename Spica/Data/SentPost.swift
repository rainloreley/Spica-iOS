//
//  SentPost.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
//

import Foundation
import SwiftyJSON

public struct SentPost {
    var id: String
    var username: String

    init(id: String, username: String) {
        self.id = id
        self.username = username
    }

    init(_ json: JSON) {
        id = json["slug"].string!
        username = json["username"].string!
    }
}

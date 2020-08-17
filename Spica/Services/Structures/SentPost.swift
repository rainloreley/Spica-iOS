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

    init(id: String) {
        self.id = id
    }

    init(_ json: JSON) {
        id = json["id"].string!
    }
}

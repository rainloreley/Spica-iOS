//
//  Label.swift
//  Spica
//
//  Created by Adrian Baumgart on 18.08.20.
//

import Foundation
import SwiftyJSON

public struct Label: Hashable, Identifiable {
    public var id: String
    var name: String
    var color: String

    init(name: String = "", color: String = "") {
        id = randomString(length: 30)
        self.name = name
        self.color = color
    }

    init(_ json: JSON) {
        id = randomString(length: 30)
        name = json["name"].string ?? ""
        color = json["color"].string ?? ""
    }
}

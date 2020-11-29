//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 14.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON

struct PushDevice: Identifiable {
    var id: String
    var type: PushDeviceType
    var token: String
    var name: String
    var created: Date

    init(_ json: JSON) {
        id = json["id"].string ?? ""
        type = PushDeviceType(rawValue: json["type"].string ?? "unknown") ?? .unknown
        token = json["pushtoken"].string ?? ""
        name = json["name"].string ?? ""
        created = Date.dateFromISOString(string: json["createdAt"].string ?? "") ?? Date()
    }
}

enum PushDeviceType: String {
    case phone
    case pad
    case mac
    case unknown
}

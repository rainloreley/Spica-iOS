//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 18.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON

struct Status {
    var id: String?
    var content: String?
    var date: Date?
    var end: Date?

    init(id: String? = nil, content: String? = nil, date: Date? = nil, end: Date? = nil) {
        self.id = id
        self.content = content
        self.date = date
        self.end = end
    }

    init(_ json: JSON) {
        if json["status"].type == .null {
            id = nil
            content = nil
            date = nil
            end = nil
        } else {
            id = json["status"]["id"].string ?? ""
            content = json["status"]["content"].string ?? ""
            date = Date.dateFromISOString(string: json["status"]["date"].string ?? "") ?? nil
            end = Date.dateFromISOString(string: json["status"]["end"].string ?? "") ?? nil
        }
    }
}

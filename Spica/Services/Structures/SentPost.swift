//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
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

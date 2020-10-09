//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON

struct XP {
    var total: Int
    var level: Int
    var levelXP: Int
    var levelXPMax: Int
    var progress: Double

    init(total: Int = 0, level: Int = 0, levelXP: Int = 0, levelXPMax: Int = 0, progress: Double = 0) {
        self.total = total
        self.level = level
        self.levelXP = levelXP
        self.levelXPMax = levelXPMax
        self.progress = progress
    }

    init(_ json: JSON) {
        total = json["total"].int ?? 0
        level = json["level"].int ?? 0
        levelXP = json["levelXp"].int ?? 0
        levelXPMax = json["levelXpMax"].int ?? 0
        progress = json["levelProgress"].double ?? 0
    }
}

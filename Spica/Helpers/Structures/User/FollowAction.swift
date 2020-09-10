//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 22.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

public enum FollowAction {
    case follow, unfollow

    var actionString: String {
        switch self {
        case .follow: return "follow"
        case .unfollow: return "unfollow"
        }
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

func countString(number: Int, singleText: String, multiText: String, includeNumber: Bool) -> String {
    if number == 1 {
        if includeNumber {
            return "\(number) \(singleText)"
        } else {
            return "\(singleText)"
        }
    } else {
        if includeNumber {
            return "\(number) \(multiText)"
        } else {
            return "\(multiText)"
        }
    }
}

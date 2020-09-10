//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 16.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

func SLocale(_ key: LocalizableKeys) -> String {
    let localized = NSLocalizedString(key.rawValue, comment: key.rawValue)
    if localized == key.rawValue { // Check if string exists in language
        guard let bundlePath = Bundle.main.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: bundlePath) else {
            return localized // If not, return english value
        }
        return NSLocalizedString(key.rawValue, tableName: nil, bundle: bundle, comment: key.rawValue)
    }
    return localized
}

//
//  SLocale.swift
//  Spica
//
//  Created by Adrian Baumgart on 16.07.20.
//

import UIKit


func SLocale(_ key: LocalizableKeys) -> String {
	return NSLocalizedString(key.rawValue, comment: key.rawValue)
}

//
//  SLocale.swift
//  Spica
//
//  Created by Adrian Baumgart on 16.07.20.
//

import UIKit

public func SLocale(_ key: LocalizableKeys) -> NSLocalizedString {
	return NSLocalizedString(key.rawValue, comment: key.rawValue)
}




//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 24.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftUI

protocol ColorPickerControllerDelegate {
	func changedColor(_ color: UIColor)
}

class ColorPickerController: ObservableObject {
	
	var delegate: ColorPickerControllerDelegate!
	
	@Published var color: Color {
		didSet {
			if #available(iOS 14.0, *) {
				delegate.changedColor(UIColor(color))
			} else {
				// Fallback on earlier versions
			}
		}
	}

	init(color: Color) {
		self.color = color
	}
}

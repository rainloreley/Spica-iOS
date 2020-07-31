//
//  HeaderProfilePictureController.swift
//  Spica
//
//  Created by Adrian Baumgart on 31.07.20.
//

import SwiftUI
import Combine

class HeaderProfilePictureController: ObservableObject {
	
	@Published var isOnline: Bool
	@Published var profilePicture: UIImage
	@Published var grow: Bool
	
	init(isOnline: Bool, profilePicture: UIImage, grow: Bool) {
		self.isOnline = isOnline
		self.profilePicture = profilePicture
		self.grow = grow
	}
	
}

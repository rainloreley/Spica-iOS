//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 21.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftUI
import Combine

class CreatePostController: ObservableObject {
	
	@Published var selectedImage: UIImage?
	@Published var enteredLink: String = ""
	@Published var progressbarController = ProgressBarController(progress: 0, color: .gray)
	@Published var parentID: String? = nil
	@Published var sendButtonEnabled: Bool = true
	@Published var showLoadingIndicator: Bool = false
	@Published var errorMessage: String = ""
	@Published var showErrorMessage: Bool = false
	@Published var showingLinkField = false
	var delegate: CreatePostDelegate?
	
	init(delegate: CreatePostDelegate?, parentID: String? = nil, preText: String = "", preLink: String = "") {
		self.delegate = delegate
		self.parentID = parentID
		self.enteredText = preText
		self.enteredLink = preLink
		if preLink != "" {
			showingLinkField = true
		}
	}
	@Published var enteredText: String = "" {
		didSet {
			let calculation = Double(enteredText.count) / Double(500)
			progressbarController.progress = Float(calculation)
		}
	}
}

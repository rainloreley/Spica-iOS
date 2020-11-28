//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 21.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation
import SwiftUI

class CreatePostController: ObservableObject {
    @Published var selectedImage: UIImage? {
        didSet {
            loadedDraftId = ""
        }
    }

    @Published var enteredLink: String = "" {
        didSet {
            loadedDraftId = ""
        }
    }

    @Published var progressbarController = ProgressBarController(progress: 0, color: .gray)
    @Published var parentID: String? = nil
    @Published var sendButtonEnabled: Bool = true
    @Published var showLoadingIndicator: Bool = false
    @Published var errorMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertType: CreatePostAlertType = .error
    @Published var showingLinkField = false
    @Published var drafts: [Draft]
    @Published var loadedDraftId: String = ""
    var delegate: CreatePostDelegate?

	init(loadedDraftId: String = "",delegate: CreatePostDelegate?, parentID: String? = nil, preText: String = "", preLink: String = "", drafts: [Draft] = []) {
		self.loadedDraftId = loadedDraftId
        self.delegate = delegate
        self.parentID = parentID
        enteredText = preText
        enteredLink = preLink
        if preLink != "" {
            showingLinkField = true
        }
        self.drafts = drafts
    }

    func loadDrafts() {
        drafts = UserDefaults.standard.structArrayData(Draft.self, forKey: "postDrafts")
        drafts.sort(by: { $0.createdAt > $1.createdAt })
    }

    func deleteCurrentDraftId() {
        var savedDrafts = UserDefaults.standard.structArrayData(Draft.self, forKey: "postDrafts")
        savedDrafts.removeAll(where: { $0.id == loadedDraftId })
        UserDefaults.standard.setStructArray(savedDrafts, forKey: "postDrafts")
    }

    func saveAsDraft() {
        var savedDrafts = UserDefaults.standard.structArrayData(Draft.self, forKey: "postDrafts")
        var newImageData: String?
        if let image = selectedImage {
            newImageData = image.pngData()?.base64EncodedString()
        }
        savedDrafts.append(.init(id: randomString(length: 30), content: enteredText, link: enteredLink == "" ? nil : enteredLink, image: newImageData, createdAt: Date()))
        UserDefaults.standard.setStructArray(savedDrafts, forKey: "postDrafts")
    }

    @Published var enteredText: String = "" {
        didSet {
            loadedDraftId = ""
            let calculation = Double(enteredText.count) / Double(500)
            progressbarController.progress = Float(calculation)
        }
    }
}

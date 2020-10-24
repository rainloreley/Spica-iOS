//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 23.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation
import SwiftUI

protocol UpdateStatusDelegate {
    func statusUpdated()
    func statusError(err: MicroError)
}

class UpdateStatusController: ObservableObject {
    @Published var enteredText: String = ""
    @Published var selectedDate: Date = Date().addingTimeInterval(86400)
    var delegate: UpdateStatusDelegate!

    func clearStatus() {
        MicroAPI.default.updateStatus(nil, time: nil) { [self] result in
            switch result {
            case let .failure(err):
                delegate.statusError(err: err)
            case .success:
                delegate.statusUpdated()
            }
        }
    }

    func updateStatus() {
        MicroAPI.default.updateStatus(enteredText, time: Int(selectedDate.timeIntervalSince(Date()))) { [self] result in
            switch result {
            case let .failure(err):
                delegate.statusError(err: err)
            case .success:
                delegate.statusUpdated()
            }
        }
    }
}

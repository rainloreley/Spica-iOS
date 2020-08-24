//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 05.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftUI

class ProgressBarController: ObservableObject {
    @Published var progress: Float {
        didSet {
            if progress == 0 {
                color = .gray
            } else if progress < 0.5 {
                color = .green
            } else if progress < 0.75 {
                color = .yellow
            } else {
                color = .red
            }
        }
    }

    @Published var color: Color

    init(progress: Float, color: Color) {
        self.progress = progress
        self.color = color
    }
}

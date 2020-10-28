//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
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

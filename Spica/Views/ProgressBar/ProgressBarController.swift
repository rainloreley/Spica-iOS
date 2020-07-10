//
//  ProgressBarController.swift
//  Spica
//
//  Created by Adrian Baumgart on 05.07.20.
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

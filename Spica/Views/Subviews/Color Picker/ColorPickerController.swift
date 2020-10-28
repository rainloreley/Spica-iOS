//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
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

//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.09.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation
import SwiftUI

class MiniPostController: ObservableObject {
    @Published var post: MiniPost?

    init(post: MiniPost?) {
        self.post = post
    }
}

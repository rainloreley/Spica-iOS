//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import UIKit

public struct NewPost {
    var content: String
    var image: UIImage?
    var type: PostType
    var parent: String?
}

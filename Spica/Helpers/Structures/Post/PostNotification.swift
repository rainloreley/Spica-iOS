//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 15.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

public struct PostNotification: Hashable {
    var post: Post
    var read: Bool

    init(post: Post, read: Bool = true) {
        self.post = post
        self.read = read
    }
}

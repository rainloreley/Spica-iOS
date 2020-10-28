//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

struct StoredBookmark: Hashable, Codable {
    var id: String
    var added: Date

    init(id: String, added: Date) {
        self.id = id
        self.added = added
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 27.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

struct Draft: Hashable, Codable, Identifiable {
    var id: String
    var content: String
    var link: String?
    var image: String?
    var createdAt: Date
}

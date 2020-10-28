//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 08.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

public struct MicroError: Error {
    var error: MicroAnalyzedError
    var action: String?
}

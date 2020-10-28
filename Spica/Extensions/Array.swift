//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 27.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

extension Array {
    func uniques<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return reduce([]) { result, element in
            let alreadyExists = result.contains(where: { $0[keyPath: keyPath] == element[keyPath: keyPath] })
            return alreadyExists ? result : result + [element]
        }
    }
}

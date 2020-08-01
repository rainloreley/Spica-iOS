//
//  AllesAPIErrorMessage.swift
//  Spica
//
//  Created by Adrian Baumgart on 02.07.20.
//

import Foundation

public struct AllesAPIErrorMessage: Error {
    var message: String
    var error: AllesAPIError
    var actionParameter: String?
    var action: AllesAPIErrorAction?
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import LocalAuthentication

func biometricType() -> BiometricType {
    let authContext = LAContext()
    if #available(iOS 11, *) {
        _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch authContext.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touch
        case .faceID:
            return .face
		@unknown default:
            return .none
        }
    } else {
        return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
    }
}

enum BiometricType {
    case none
    case touch
    case face
}

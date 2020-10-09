//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Alamofire
import Combine
import Foundation
import SwiftKeychainWrapper
import SwiftyJSON

public class MicroAPI {
    static let `default` = MicroAPI()
    var subscriptions = Set<AnyCancellable>()

    func loadAuthKey() -> String {
        // return KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
        return "add token here, i guess"
    }

    func isError(_ response: AFDataResponse<Any>) -> MicroAnalyzedError {
        if response.data == nil { return .init(isError: true, name: "spica_nodata") }
        let json = JSON(response.data!)
        if json["err"].exists() {
            return .init(isError: true, name: json["err"].string ?? "unknown error")
        }
        return .init(isError: false, name: "")
    }
}

struct MicroAnalyzedError {
    var isError: Bool
    var name: String
}

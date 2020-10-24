//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Alamofire
import Combine
import Foundation
import SwiftyJSON

extension MicroAPI {
    func searchUser(_ query: String, promise: @escaping (Result<[User], MicroError>) -> Void) {
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        AF.request("https://micro.alles.cx/api/users?nt=\(escapedQuery)", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
            switch response.result {
            case .success:
                let possibleError = isError(response)
                if !possibleError.error.isError {
                    let responseJSON = JSON(response.data!)
                    let users = responseJSON["users"].map {
                        User($1)
                    }
                    return promise(.success(users))
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }
}

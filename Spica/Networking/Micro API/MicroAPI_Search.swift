//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the MIT License
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
                    var users = responseJSON["users"].map {
                        User($1)
                    }

                    let usernameDispatchGroup = DispatchGroup()

                    usernameDispatchGroup.enter()

                    searchUserByUsername(query) { userResult in
                        switch userResult {
                        case .failure:
                            usernameDispatchGroup.leave()
                        case let .success(userByUsername):
                            users.append(userByUsername)
                            usernameDispatchGroup.leave()
                        }
                    }

                    usernameDispatchGroup.notify(queue: .global(qos: .utility)) {
                        let uidDispatchGroup = DispatchGroup()
                        uidDispatchGroup.enter()
                        loadUser(query) { uidResult in
                            switch uidResult {
                            case .failure:
                                uidDispatchGroup.leave()
                            case let .success(uidUser):
                                users.append(uidUser)
                                uidDispatchGroup.leave()
                            }
                        }

                        uidDispatchGroup.notify(queue: .global(qos: .utility)) {
                            promise(.success(users.uniques(by: \.id)))
                        }
                    }
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }

    func searchUserByUsername(_ username: String, promise: @escaping (Result<User, MicroError>) -> Void) {
        let charsForUsername: Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        let escapedForUsername = String(username.filter { charsForUsername.contains($0) })
        loadIdByUsername(escapedForUsername, allowEmptyUsername: true) { [self] usernameResult in
            switch usernameResult {
            case .failure:
                return promise(.failure(.init(error: .init(isError: true, name: "notFOund"), action: nil)))
            case let .success(id):
                loadUser(id) { userResult in
                    switch userResult {
                    case .failure:
                        return promise(.failure(.init(error: .init(isError: true, name: "notFOund"), action: nil)))
                    case let .success(user):
                        return promise(.success(user))
                    }
                }
            }
        }
    }
}

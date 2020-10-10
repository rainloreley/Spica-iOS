//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
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

extension MicroAPI {
    func signIn(name: String, tag: String, password: String) -> Future<String, MicroError> {
        Future<String, MicroError> { promise in
            AF.request("https://alles.cx/api/login", method: .post, parameters: [
                "name": name,
                "tag": tag,
                "password": password,
            ], encoding: JSONEncoding.default).responseJSON(queue: .global(qos: .utility)) { [self] response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        let signinJSON = JSON(response.data!)
                        if signinJSON["token"].exists() {
                            KeychainWrapper.standard.set(signinJSON["token"].string!, forKey: "dev.abmgrt.spica.user.token")
                            loadSignedinUser()
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(err):
                                        return promise(.failure(err))
                                    default: break
                                    }
                                } receiveValue: { user in
                                    print(user)
                                    KeychainWrapper.standard.set(user.id, forKey: "dev.abmgrt.spica.user.id")
                                    KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.name")
                                    KeychainWrapper.standard.set(user.tag, forKey: "dev.abmgrt.spica.user.tag")
                                }.store(in: &subscriptions)

                            promise(.success(signinJSON["token"].string!))
                        } else {
                            promise(.failure(.init(error: .init(isError: true, name: "login_noToken"), action: nil)))
                        }
                    } else {
                        return promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }

    func loadSignedinUser() -> Future<User, MicroError> {
        Future<User, MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/me", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        let userJSON = JSON(response.data!)
                        promise(.success(User(userJSON)))
                    } else {
                        return promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }

    func loadUser(_ id: String) -> Future<User, MicroError> {
        Future<User, MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { userResponse in
                switch userResponse.result {
                case .success:
                    let possibleError = isError(userResponse)
                    if !possibleError.error.isError {
                        let userJSON = JSON(userResponse.data!)
                        promise(.success(User(userJSON)))
                    } else {
                        promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }

    func loadUserPosts(_ id: String) -> Future<[Post], MicroError> {
        Future<[Post], MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        let userJSON = JSON(response.data!)
                        var userPosts = [Post]()
                        var errorCount = 0
                        var latestError: MicroError?
                        let dispatchGroup = DispatchGroup()
                        for json in userJSON["posts"]["recent"].arrayValue {
                            dispatchGroup.enter()
                            loadPost(json.string ?? "")
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(err):
                                        errorCount += 1
                                        latestError = err
                                        dispatchGroup.leave()
                                    default: break
                                    }
                                } receiveValue: { userpost in
                                    userPosts.append(userpost)
                                    dispatchGroup.leave()
                                }.store(in: &subscriptions)
                        }
                        dispatchGroup.notify(queue: .main) {
                            userPosts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })

                            if userPosts.isEmpty, errorCount > 0 {
                                return promise(.failure(latestError!))
                            } else {
                                return promise(.success(userPosts))
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
    }

    func followUnfollowUser(_ action: FollowUnfollow, id: String) -> Future<String, MicroError> {
        Future<String, MicroError> { [self] promise in
            print(action.rawValue)
            print(id)
            AF.request("https://micro.alles.cx/api/users/\(id)/\(action.rawValue)", method: .post, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        promise(.success(id))
                    } else {
                        promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }
}

enum FollowUnfollow: String {
    case follow
    case unfollow
}

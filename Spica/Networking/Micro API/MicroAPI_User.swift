//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
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
    func signIn(name: String, tag: String, password: String, promise: @escaping (Result<String, MicroError>) -> Void) {
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

                        loadSignedinUser { result in
                            switch result {
                            case let .failure(err):
                                return promise(.failure(err))
                            case let .success(user):
                                KeychainWrapper.standard.set(user.id, forKey: "dev.abmgrt.spica.user.id")
                                KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.name")
                                KeychainWrapper.standard.set(user.tag, forKey: "dev.abmgrt.spica.user.tag")
                                promise(.success(signinJSON["token"].string!))
                            }
                        }
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

    func loadSignedinUser(promise: @escaping (Result<User, MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/me", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
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

    func loadUser(_ id: String, loadStatus: Bool = false, loadRing: Bool = false, promise: @escaping (Result<User, MicroError>) -> Void) {
        loadIdByUsername(id, allowEmptyUsername: true) { [self] result in
            switch result {
            case let .failure(err):
                return promise(.failure(err))
            case let .success(usernameID):
                let newID = usernameID != "" ? usernameID : id
                AF.request("https://micro.alles.cx/api/users/\(newID)", method: .get, headers: [
                    "Authorization": loadAuthKey(),
                ]).responseJSON(queue: .global(qos: .utility)) { userResponse in
                    switch userResponse.result {
                    case .success:

                        let possibleError = isError(userResponse)
                        if !possibleError.error.isError {
                            let userJSON = JSON(userResponse.data!)
                            var user: User = .init(userJSON)

                            if loadStatus {
                                loadUserStatus(user.id) { result in
                                    switch result {
                                    case let .failure(err):
                                        promise(.failure(err))
                                    case let .success(status):
                                        user.status = status

                                        SpicaPushAPI.default.getUserData { pushresult in
                                            switch pushresult {
                                            case .failure:
                                                user.spicaUserHasPushAccount = false
                                                user.userSubscribedTo = false
                                                if loadRing {
                                                    FlagServerAPI.default.loadUserRing(user.id) { ringResult in
                                                        switch ringResult {
                                                        case .failure:
                                                            user.ring = .none
                                                            promise(.success(user))
                                                        case let .success(ring):
                                                            user.ring = ring
                                                            promise(.success(user))
                                                        }
                                                    }
                                                } else {
                                                    promise(.success(user))
                                                }
                                            case let .success(pushuser):
                                                if pushuser.usersSubscribedTo.contains(where: { $0.id == user.id }) {
                                                    user.spicaUserHasPushAccount = true
                                                    user.userSubscribedTo = true
                                                } else {
                                                    user.spicaUserHasPushAccount = true
                                                    user.userSubscribedTo = false
                                                }

                                                if loadRing {
                                                    FlagServerAPI.default.loadUserRing(user.id) { ringResult in
                                                        switch ringResult {
                                                        case .failure:
                                                            user.ring = .none
                                                            promise(.success(user))
                                                        case let .success(ring):
                                                            user.ring = ring
                                                            promise(.success(user))
                                                        }
                                                    }
                                                } else {
                                                    promise(.success(user))
                                                }
                                            }
                                        }
                                    }
                                }
                            } else if loadRing {
                                FlagServerAPI.default.loadUserRing(user.id) { ringResult in
                                    switch ringResult {
                                    case .failure:
                                        user.ring = .none
                                        promise(.success(user))
                                    case let .success(ring):
                                        user.ring = ring
                                        promise(.success(user))
                                    }
                                }
                            } else {
                                promise(.success(user))
                            }
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

    func loadIdByUsername(_ username: String, allowEmptyUsername: Bool = false, completionHandler: @escaping (Result<String, MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/username/\(username)", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
            switch response.result {
            case .success:
                let possibleError = isError(response)
                if !possibleError.error.isError {
                    let usernameJSON = JSON(response.data!)
                    if usernameJSON["id"].exists(), usernameJSON["id"].string != nil {
                        return completionHandler(.success(usernameJSON["id"].string!))
                    } else {
                        if allowEmptyUsername {
                            return completionHandler(.success(""))
                        } else {
                            return completionHandler(.failure(.init(error: .init(isError: true, name: "usernameNotFound"), action: nil)))
                        }
                    }
                } else {
                    if allowEmptyUsername {
                        return completionHandler(.success(""))
                    } else {
                        return completionHandler(.failure(possibleError))
                    }
                }
            case let .failure(err):
                return completionHandler(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }

    func loadUserPosts(_ id: String, promise: @escaping (Result<[Post], MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
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
                        loadPost(json.string ?? "") { result in
                            switch result {
                            case let .failure(err):
                                errorCount += 1
                                latestError = err
                                dispatchGroup.leave()
                            case let .success(userpost):
                                userPosts.append(userpost)
                                dispatchGroup.leave()
                            }
                        }
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

    func followUnfollowUser(_ action: FollowUnfollow, id: String, promise: @escaping (Result<String, MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/users/\(id)/\(action.rawValue)", method: .post, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
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

    func loadFollowers(promise: @escaping (Result<[User], MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/followers", method: .get, headers: [
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
                    promise(.success(users))
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }

    func loadFollowing(promise: @escaping (Result<[User], MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/following", method: .get, headers: [
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
                    promise(.success(users))
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }
}

enum FollowUnfollow: String {
    case follow
    case unfollow
}

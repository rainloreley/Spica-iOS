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
			
			let dispatchGroup = DispatchGroup()
			dispatchGroup.enter()
			var newID = id
			loadIdByUsername(newID)
				.receive(on: RunLoop.main)
				.sink {
					switch $0 {
						case let .failure(err):
							print(err)
							dispatchGroup.leave()
						default: break
					}
				} receiveValue: { (usernameID) in
					newID = usernameID
					print(newID)
					dispatchGroup.leave()
				}.store(in: &subscriptions)
			
			
			dispatchGroup.notify(queue: .main) {
				AF.request("https://micro.alles.cx/api/users/\(newID)", method: .get, headers: [
					"Authorization": loadAuthKey(),
				]).responseJSON(queue: .global(qos: .utility)) { userResponse in
					switch userResponse.result {
					case .success:
						
						let possibleError = isError(userResponse)
						if !possibleError.error.isError {
							let userJSON = JSON(userResponse.data!)
							var user: User = .init(userJSON)
							
							loadUserStatus(user.id)
								.receive(on: RunLoop.main)
								.sink {
									switch $0 {
										case let .failure(err):
											promise(.failure(err))
										default: break
									}
								} receiveValue: { (status) in
									user.status = status
									promise(.success(user))
								}.store(in: &subscriptions)
							
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
	
	func loadUserStatus(_ id: String) -> Future<Status, MicroError> {
		Future<Status, MicroError> { [self] promise in
			AF.request("https://wassup.alles.cc/\(id)", method: .get).responseJSON(queue: .global(qos: .utility)) { (response) in
				switch response.result {
					case .success:
						let possibleError = isError(response)
						if !possibleError.error.isError {
							let statusJSON = JSON(response.data!)
							promise(.success(.init(statusJSON)))
						}
						else {
							promise(.failure(possibleError))
						}
					case let .failure(err):
						return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
				}
			}
		}
	}
	
	func loadIdByUsername(_ username: String) -> Future<String, MicroError> {
		Future<String, MicroError> { [self] promise in
			AF.request("https://micro.alles.cx/api/username/\(username)", method: .get, headers: [
						"Authorization": loadAuthKey(),
			]).responseJSON(queue: .global(qos: .utility)) { (response) in
				switch response.result {
					case .success:
						let possibleError = isError(response)
						if !possibleError.error.isError {
							let usernameJSON = JSON(response.data!)
							let userID = usernameJSON["id"].string
							if userID != nil {
								return promise(.success(userID!))
							}
							else {
								return promise(.failure(.init(error: .init(isError: true, name: "usernameNotFound"), action: nil)))
							}
						}
						else {
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

    func loadFollowers() -> Future<[User], MicroError> {
        Future<[User], MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/followers", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
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

    func loadFollowing() -> Future<[User], MicroError> {
        Future<[User], MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/following", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
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
}

enum FollowUnfollow: String {
    case follow
    case unfollow
}

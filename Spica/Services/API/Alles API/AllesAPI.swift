//
//  AllesAPI.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Alamofire
import Combine
import Foundation
import SwiftKeychainWrapper
import SwiftyJSON
import UIKit

public class AllesAPI {
    static let `default` = AllesAPI()

    private var subscriptions = Set<AnyCancellable>()

    public func signInUser(username: String, password: String) -> Future<SignedInUser, AllesAPIErrorMessage> {
        Future<SignedInUser, AllesAPIErrorMessage> { promise in
            AF.request("https://alles.cx/api/login", method: .post, parameters: [
                "username": username,
                "password": password,
            ], encoding: JSONEncoding.default).responseJSON(queue: .global(qos: .utility)) { [self] response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            if responseJSON["token"].string != nil {
                                KeychainWrapper.standard.set(responseJSON["token"].string!, forKey: "dev.abmgrt.spica.user.token")

                                AllesAPI.default.loadUser(username: username)
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err): return promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { user in
                                        KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.username")
                                        KeychainWrapper.standard.set(user.id, forKey: "dev.abmgrt.spica.user.id")

                                        SpicAPI.getPrivacyPolicy()
                                            .receive(on: RunLoop.main)
                                            .sink {
                                                switch $0 {
                                                case .failure:
                                                    promise(.success(SignedInUser(username: username, sessionToken: responseJSON["token"].string!)))
                                                default: break
                                                }
                                            } receiveValue: { privacy in
                                                UserDefaults.standard.set(privacy.updated, forKey: "spica_privacy_accepted_version")
                                                promise(.success(SignedInUser(username: username, sessionToken: responseJSON["token"].string!)))
                                            }.store(in: &subscriptions)

                                    }.store(in: &subscriptions)

                            } else {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_noLoginTokenReturned")))
                            }
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public static func loadFeed(cache _: CachePolicy = .remote) -> Future<[Post], AllesAPIErrorMessage> {
        Future<[Post], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/feed", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let tempPosts = responseJSON["feed"].map { _, json in
                                Post(json)
                            }
                            promise(.success(tempPosts))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.localizedDescription)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func sendOnlineStatus() {
        guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
            return
        }
        AF.request("https://online.alles.cx", method: .post, parameters: nil, headers: [
            "Authorization": authKey,
        ]).response(queue: .global(qos: .utility)) { _ in }
    }

    public func loadUser(username: String) -> Future<User, AllesAPIErrorMessage> {
        Future<User, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/users/\(username)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            AF.request("https://online.alles.cx/\(responseJSON["id"].string!)", method: .get, parameters: nil, headers: [
                                "Authorization": authKey,
                            ]).response(queue: .global(qos: .utility)) { onlineResponse in
                                switch onlineResponse.result {
                                case .success:
                                    let data = String(data: onlineResponse.data!, encoding: .utf8)
                                    let isOnline = data == "🟢"
                                    let newUser = User(responseJSON, isOnline: isOnline)
                                    promise(.success(newUser))
                                case let .failure(err):
                                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                                    apiError.message.append("\nError: \(err.errorDescription!)")
                                    promise(.failure(apiError))
                                }
                            }
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public static func loadFollowers() -> Future<Followers, AllesAPIErrorMessage> {
        Future<Followers, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }

            AF.request("https://alles.cx/api/followers", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let followers = responseJSON["followers"].map { _, json in
                                FollowUser(json)
                            }

                            let following = responseJSON["following"].map { _, json in
                                FollowUser(json)
                            }

                            promise(.success(Followers(followers: followers, following: following)))

                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }
                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func loadUserPosts(user: User) -> Future<[Post], AllesAPIErrorMessage> {
        Future<[Post], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/users/\(user.id)?posts", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPosts = responseJSON["posts"].map { _, json in
                                Post(json)
                            }
                            tempPosts.sort(by: { $0.date.compare($1.date) == .orderedDescending })
                            promise(.success(tempPosts))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func loadMentions() -> Future<[Post], AllesAPIErrorMessage> {
        Future<[Post], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/mentions", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPosts = responseJSON["mentions"].map { _, json in
                                Post(json)
                            }

                            tempPosts.sort { $0.date.compare($1.date) == .orderedDescending }
                            promise(.success(tempPosts))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public static func loadTag(tag: String) -> Future<Tag, AllesAPIErrorMessage> {
        Future<Tag, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/tag/\(tag)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPosts = responseJSON["posts"].map { _, json in
                                Post(json)
                            }

                            tempPosts.sort { $0.date.compare($1.date) == .orderedDescending }

                            let tag = Tag(name: responseJSON["name"].string!, posts: tempPosts)

                            promise(.success(tag))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    static func loadPost(id: String) -> Future<Post, AllesAPIErrorMessage> {
        Future<Post, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }

            AF.request("https://alles.cx/api/post/\(id)?children", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let post = Post(responseJSON)
                            promise(.success(post))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    static func loadPostDetail(id: String) -> Future<PostDetail, AllesAPIErrorMessage> {
        Future<PostDetail, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/post/\(id)?children", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPostDetail = PostDetail(ancestors: [], post: Post.empty(author: User()), replies: [])

                            tempPostDetail.post = Post(responseJSON)
                            tempPostDetail.post.author = User(responseJSON["author"], isOnline: false)
                            tempPostDetail.replies = responseJSON["replies"].map {
                                Post($1)
                            }

                            tempPostDetail.ancestors = responseJSON["ancestors"].map {
                                if $1["removed"].exists() {
                                    return .deleted
                                }
                                return Post($1)
                            }
                            promise(.success(tempPostDetail))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func sendPost(newPost: NewPost) -> Future<SentPost, AllesAPIErrorMessage> {
        Future<SentPost, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            var newPostConstruct: [String: String] = [
                "content": newPost.content,
            ]

            if let image = newPost.image {
                let base64Image = "data:image/jpeg;base64,\((image.jpegData(compressionQuality: 0.5)?.base64EncodedString())!)"
                newPostConstruct["image"] = "\(base64Image)"
            }

            if let parent = newPost.parent {
                newPostConstruct["parent"] = parent
            }

            AF.request("https://alles.cx/api/post", method: .post, parameters: newPostConstruct, encoding: JSONEncoding.prettyPrinted, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            if responseJSON["slug"].exists() {
                                promise(.success(SentPost(responseJSON)))
                            }
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func deletePost(id: String) -> Future<EmptyCompletion, AllesAPIErrorMessage> {
        Future<EmptyCompletion, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }

            AF.request("https://alles.cx/api/post/\(id)/remove", method: .post, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            promise(.success(.init()))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case let .failure(err):
                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    apiError.message.append("\nError: \(err.errorDescription!)")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func votePost(post: Post, value: Int) -> Future<Post, AllesAPIErrorMessage> {
        Future<Post, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            if value == -1 || value == 0 || value == 1 {
                AF.request("https://alles.cx/api/post/\(post.id)/vote", method: .post, parameters: ["vote": value], encoding: JSONEncoding.default, headers: [
                    "Authorization": authKey,
                ]).responseJSON(queue: .global(qos: .utility)) { response in
                    switch response.result {
                    case .success:

                        let responseJSON = JSON(response.data!)
                        if !responseJSON["err"].exists() {
                            if response.response?.statusCode == 200 {
                                promise(.success(post))
                            } else {
                                if response.response!.statusCode == 401 {
                                    promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                                } else {
                                    var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                    apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                    promise(.failure(apiError))
                                }
                            }

                        } else {
                            let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                            promise(.failure(apiError))
                        }

                    case let .failure(err):
                        var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                        apiError.message.append("\nError: \(err.errorDescription!)")
                        promise(.failure(apiError))
                    }
                }
            } else {
                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_valueNotAllowed")))
            }
        }
    }

    public func performFollowAction(username: String, action: FollowAction) -> Future<FollowAction, AllesAPIErrorMessage> {
        Future<FollowAction, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://alles.cx/api/users/\(username)/\(action.actionString)", method: .post, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            promise(.success(action))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case .failure:
                    let apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func updateProfile(newData: UpdateUser) -> Future<UpdateUser, AllesAPIErrorMessage> {
        Future<UpdateUser, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            let userConstruct = [
                "about": newData.about,
                "name": newData.name,
                "nickname": newData.nickname,
            ]
            AF.request("https://alles.cx/api/updateProfile", method: .post, parameters: userConstruct, encoding: JSONEncoding.prettyPrinted, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            promise(.success(newData))
                        } else {
                            if response.response!.statusCode == 401 {
                                promise(.failure(AllesAPIErrorHandler.default.returnError(error: "badAuthorization")))
                            } else {
                                var apiError = AllesAPIErrorHandler.default.returnError(error: "spica_invalidStatusCode")
                                apiError.message.append("\n(Code: \(response.response!.statusCode))")
                                promise(.failure(apiError))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        promise(.failure(apiError))
                    }

                case .failure:
                    let apiError = AllesAPIErrorHandler.default.returnError(error: "spica_unknownError")
                    promise(.failure(apiError))
                }
            }
        }
    }

    public func errorHandling(error: AllesAPIErrorMessage, caller: UIView) {
        EZAlertController.alert(SLocale(.ERROR), message: error.message, buttons: ["Ok"]) { _, _ in

            if error.action != nil, error.actionParameter != nil {
                if error.action == AllesAPIErrorAction.navigate, error.actionParameter == "login" {
                    let mySceneDelegate = caller.window!.windowScene!.delegate as! SceneDelegate
                    mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                    mySceneDelegate.window?.makeKeyAndVisible()
                }
            }
        }
    }
}

public struct EmptyCompletion {}

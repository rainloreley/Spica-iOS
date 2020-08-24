//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 30.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Alamofire
import Combine
import Foundation
import SwiftKeychainWrapper
import SwiftUI
import SwiftyJSON
import UIKit

public class AllesAPI {
    static let `default` = AllesAPI()

    private var subscriptions = Set<AnyCancellable>()

    public func signInUser(name: String, tag: String, password: String) -> Future<SignedInUser, AllesAPIErrorMessage> {
        Future<SignedInUser, AllesAPIErrorMessage> { promise in
            AF.request("https://alles.cx/api/login", method: .post, parameters: [
                "name": name,
                "tag": tag,
                "password": password,
            ], encoding: JSONEncoding.default).responseJSON(queue: .global(qos: .utility)) { [self] response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            if responseJSON["token"].string != nil {
                                KeychainWrapper.standard.set(responseJSON["token"].string!, forKey: "dev.abmgrt.spica.user.token")

                                AllesAPI.default.loadMe()
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err): return promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { user in
                                        KeychainWrapper.standard.set(user.id, forKey: "dev.abmgrt.spica.user.id")
                                        KeychainWrapper.standard.set(user.name, forKey: "dev.abmgrt.spica.user.name")
                                        KeychainWrapper.standard.set(user.tag, forKey: "dev.abmgrt.spica.user.tag")

                                        SpicAPI.getPrivacyPolicy()
                                            .receive(on: RunLoop.main)
                                            .sink {
                                                switch $0 {
                                                case .failure:
                                                    promise(.success(SignedInUser(id: user.id, sessionToken: responseJSON["token"].string!)))
                                                default: break
                                                }
                                            } receiveValue: { privacy in
                                                UserDefaults.standard.set(privacy.updated, forKey: "spica_privacy_accepted_version")
                                                promise(.success(SignedInUser(id: user.id, sessionToken: responseJSON["token"].string!)))
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

    public func loadMe() -> Future<User, AllesAPIErrorMessage> {
        Future<User, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/me", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            promise(.success(User(id: responseJSON["id"].string!, name: responseJSON["name"].string!, tag: responseJSON["tag"].string!, nickname: responseJSON["nickname"].string!, plus: responseJSON["plus"].bool!)))
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

    public func loadFeed(loadBefore: Int? = nil) -> Future<[Post], AllesAPIErrorMessage> {
        Future<[Post], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }

            let url = loadBefore != nil ? "https://micro.alles.cx/api/feed?before=\(loadBefore!)" : "https://micro.alles.cx/api/feed"
            AF.request(url, method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let disGroup = DispatchGroup()
                            var tempPosts = [Post]()
                            for json in responseJSON["posts"].arrayValue {
                                disGroup.enter()
                                // tempPosts.append(Post(id: json.string!, author: User(id: json.string!, name: json.string!, tag: "0000"), author_id: json.string!))
                                AllesAPI.default.loadPost(id: json.string!)
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err):
                                            promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { post in
                                        tempPosts.append(post)
                                        disGroup.leave()
                                    }.store(in: &self.subscriptions)
                            }

                            disGroup.notify(queue: .main) {
                                tempPosts.sort(by: { $0.created.compare($1.created) == .orderedDescending })
                                promise(.success(tempPosts))
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
        AF.request("https://micro.alles.cx/api/online", method: .post, parameters: nil, headers: [
            "Authorization": authKey,
        ]).response(queue: .global(qos: .utility)) { _ in }
    }

    public func markNotificationsAsRead() {
        guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
            return
        }

        AF.request("https://micro.alles.cx/api/mentions/read", method: .post, headers: [
            "Authorization": authKey,
        ])
            .responseJSON { _ in
            }
    }

    public func loadUser(id: String) -> Future<User, AllesAPIErrorMessage> {
        Future<User, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var newUser = User(responseJSON, isOnline: false)
                            var stringLabels = [String]()
                            for i in responseJSON["labels"].arrayValue {
                                stringLabels.append(i.string!)
                            }
                            SpicAPI.getLabels(stringLabels)
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(error):
                                        promise(.failure(error))
                                    default: break
                                    }
                                } receiveValue: { labels in
                                    newUser.labels = labels
                                    AF.request("https://micro.alles.cx/api/users/\(id)/online", method: .get, parameters: nil, headers: [
                                        "Authorization": authKey,
                                    ]).responseJSON { responseOnline in
                                        switch response.result {
                                        case .success:
                                            let onlineJSON = JSON(responseOnline.data!)
                                            if !responseJSON["err"].exists() {
                                                if response.response?.statusCode == 200 {
                                                    newUser.isOnline = onlineJSON["online"].bool ?? false
                                                    promise(.success(newUser))
                                                } else {
                                                    promise(.success(newUser))
                                                }
                                            } else {
                                                promise(.success(newUser))
                                            }
                                        case .failure:
                                            promise(.success(newUser))
                                        }
                                    }
                                }.store(in: &self.subscriptions)

                            /* AF.request("https://online.alles.cx/\(responseJSON["id"].string!)", method: .get, parameters: nil, headers: [
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
                             } */
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

            AF.request("https://micro.alles.cx/api/followers", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var followUsers = [User]()
                            for i in responseJSON["users"].arrayValue {
                                let avatarURL = i["avatar"].exists() ? URL(string: "https://fs.alles.cx/\(i["avatar"].string!)") : URL(string: "https://avatar.alles.cc/\(i["id"].string!)")
                                followUsers.append(User(id: i["id"].string!, name: i["name"].string ?? "", tag: i["tag"].string ?? "", alles: i["alles"].bool ?? false, imgURL: avatarURL))
                            }

                            followUsers.sort(by: { $0.name.lowercased() < $1.name.lowercased() })

                            AF.request("https://micro.alles.cx/api/following", method: .get, parameters: nil, headers: [
                                "Authorization": authKey,
                            ]).responseJSON { response2 in
                                switch response2.result {
                                case .success:
                                    let response2JSON = JSON(response2.data!)
                                    if !response2JSON["err"].exists() {
                                        if response2.response?.statusCode == 200 {
                                            var followingUsers = [User]()
                                            for i in response2JSON["users"].arrayValue {
                                                let avatarURL = i["avatar"].exists() ? URL(string: "https://fs.alles.cx/\(i["avatar"].string!)") : URL(string: "https://avatar.alles.cc/\(i["id"].string!)")
                                                followingUsers.append(User(id: i["id"].string!, name: i["name"].string ?? "", tag: i["tag"].string ?? "", alles: i["alles"].bool ?? false, imgURL: avatarURL))
                                            }

                                            followingUsers.sort(by: { $0.name.lowercased() < $1.name.lowercased() })

                                            promise(.success(Followers(followers: followUsers, following: followingUsers)))
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

                            /* let followers = responseJSON["followers"].map { _, json in
                                 FollowUser(json)
                             }

                             let following = responseJSON["following"].map { _, json in
                                 FollowUser(json)
                             } */

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
            AF.request("https://micro.alles.cx/api/users/\(user.id)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let disGroup = DispatchGroup()
                            var tempPosts = [Post]()
                            for json in responseJSON["posts"]["recent"].arrayValue {
                                disGroup.enter()
                                // tempPosts.append(Post(id: json.string!, author: User(id: json.string!, name: json.string!, tag: "0000"), author_id: json.string!))
                                AllesAPI.default.loadPost(id: json.string!)
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err):
                                            promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { post in
                                        tempPosts.append(post)
                                        disGroup.leave()
                                    }.store(in: &self.subscriptions)
                            }

                            disGroup.notify(queue: .main) {
                                tempPosts.sort(by: { $0.created.compare($1.created) == .orderedDescending })
                                promise(.success(tempPosts))
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

    public func getUnreadMentions() -> Future<[String], AllesAPIErrorMessage> {
        Future<[String], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/mentions?unread", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var postIDs = [String]()
                            for i in responseJSON["posts"].arrayValue {
                                postIDs.append(i["id"].string!)
                            }
                            promise(.success(postIDs))
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

    public func loadMentions() -> Future<[PostNotification], AllesAPIErrorMessage> {
        Future<[PostNotification], AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/mentions", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPosts = [PostNotification]()
                            let disGroup = DispatchGroup()
                            for notification in responseJSON["posts"].arrayValue {
                                disGroup.enter()
                                let notificationID = notification["id"].string!

                                AllesAPI.default.loadPost(id: notificationID)
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err):
                                            disGroup.leave()
                                            promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { post in

                                        tempPosts.append(PostNotification(post: post, read: notification["read"].bool ?? true))
                                        disGroup.leave()
                                    }.store(in: &self.subscriptions)
                            }

                            disGroup.notify(queue: .main) {
                                tempPosts.sort { $0.post.created.compare($1.post.created) == .orderedDescending }
                                promise(.success(tempPosts))
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

    public func loadTag(tag: String) -> Future<Tag, AllesAPIErrorMessage> {
        Future<Tag, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/tags/\(tag)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            let disGroup = DispatchGroup()
                            var tempPosts = [Post]()
                            for json in responseJSON["posts"].arrayValue {
                                disGroup.enter()
                                // tempPosts.append(Post(id: json.string!, author: User(id: json.string!, name: json.string!, tag: "0000"), author_id: json.string!))
                                AllesAPI.default.loadPost(id: json.string!)
                                    .receive(on: RunLoop.main)
                                    .sink {
                                        switch $0 {
                                        case let .failure(err):
                                            promise(.failure(err))
                                        default: break
                                        }
                                    } receiveValue: { post in
                                        tempPosts.append(post)
                                        disGroup.leave()
                                    }.store(in: &self.subscriptions)
                            }

                            disGroup.notify(queue: .main) {
                                tempPosts.sort(by: { $0.created.compare($1.created) == .orderedDescending })
                                let tag = Tag(name: tag, posts: tempPosts)
                                promise(.success(tag))
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

    public func loadPost(id: String) -> Future<Post, AllesAPIErrorMessage> {
        Future<Post, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }

            AF.request("https://micro.alles.cx/api/posts/\(id)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        var userSubscriptions = Set<AnyCancellable>()
                        if response.response?.statusCode == 200 {
                            var post = Post(responseJSON, mentionedUsers: [])
                            let author_id = responseJSON["author"].string!

                            var author_img_url = ""
                            if let fsId = responseJSON["users"][author_id]["avatar"].string {
                                author_img_url = "https://fs.alles.cx/\(fsId)"
                            } else {
                                author_img_url = "https://avatar.alles.cc/\(author_id)"
                            }

                            post.author = User(id: author_id, name: responseJSON["users"][author_id]["name"].string!, nickname: responseJSON["users"][author_id]["nickname"].string!, plus: responseJSON["users"][author_id]["plus"].bool!, alles: responseJSON["users"][author_id]["alles"].bool!, imgURL: URL(string: author_img_url)!)
                            DispatchQueue.main.async {
                                let postContent = post.content.replacingOccurrences(of: "\n", with: " \n ")
                                let splitContent = postContent.split(separator: " ")
                                let disGroup = DispatchGroup()
                                if splitContent.count > 0 {
                                    for word in splitContent {
                                        disGroup.enter()
                                        if word.hasPrefix("@"), word.count > 1 {
                                            var userID = removeSpecialCharsFromString(text: String(word))
                                            userID.remove(at: userID.startIndex)
                                            if responseJSON["users"][userID].exists() {
                                                var mentionedUserData = responseJSON["users"][userID]
                                                mentionedUserData["id"].stringValue = userID
                                                post.mentionedUsers.append(User(mentionedUserData))
                                                /* post.mentionedUsers.append(User(id: userID, name: responseJSON["users"][userID]["name"].string!, nickname: responseJSON["users"][userID]["nickname"].string!, plus: responseJSON["users"][userID]["plus"].bool!, alles: responseJSON["users"][userID]["alles"].bool!)) */
                                                disGroup.leave()
                                            } else {
                                                AllesAPI.default.loadUser(id: userID)
                                                    .receive(on: RunLoop.current)
                                                    .sink {
                                                        switch $0 {
                                                        case let .failure(error):
                                                            disGroup.leave()
                                                        default: break
                                                        }
                                                    } receiveValue: { mentionedUser in
                                                        post.mentionedUsers.append(mentionedUser)
                                                        disGroup.leave()
                                                    }
                                                    .store(in: &self.subscriptions)
                                            }
                                        } else {
                                            disGroup.leave()
                                        }
                                    }

                                    disGroup.notify(queue: .main) {
                                        promise(.success(post))
                                    }
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

    public func loadPostDetail(id: String) -> Future<PostDetail, AllesAPIErrorMessage> {
        Future<PostDetail, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/posts/\(id)", method: .get, parameters: nil, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            var tempPostDetail = PostDetail(ancestors: [], post: Post(responseJSON, mentionedUsers: []), replies: [])
                            AllesAPI.default.loadPost(id: responseJSON["id"].string!)
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(err):
                                        promise(.failure(err))
                                    default: break
                                    }
                                } receiveValue: { post in
                                    tempPostDetail.post = post

                                    let disGroup = DispatchGroup()

                                    for child in responseJSON["children"]["list"].arrayValue {
                                        disGroup.enter()
                                        AllesAPI.default.loadPost(id: child.string!)
                                            .receive(on: RunLoop.main)
                                            .sink {
                                                switch $0 {
                                                case let .failure(err):
                                                    disGroup.leave()
                                                    promise(.failure(err))
                                                default: break
                                                }
                                            } receiveValue: { childrenPost in
                                                tempPostDetail.replies.append(childrenPost)
                                                disGroup.leave()

                                            }.store(in: &subscriptions)
                                    }

                                    disGroup.notify(queue: .main) {
                                        let ancDisGroup = DispatchGroup()

                                        var highestAncestor: Post? {
                                            didSet {
                                                if highestAncestor?.parent_id != nil {
                                                    ancDisGroup.enter()
                                                    AllesAPI.default.loadPost(id: highestAncestor!.parent_id!)
                                                        .receive(on: RunLoop.main)
                                                        .sink {
                                                            switch $0 {
                                                            case let .failure(err):
                                                                ancDisGroup.leave()
                                                                highestAncestor?.parent_id = nil
                                                                promise(.failure(err))
                                                            default: break
                                                            }
                                                        } receiveValue: { ancPost in
                                                            tempPostDetail.ancestors.append(ancPost)
                                                            highestAncestor = ancPost
                                                            ancDisGroup.leave()
                                                        }.store(in: &subscriptions)
                                                }
                                            }
                                        }

                                        highestAncestor = tempPostDetail.post

                                        ancDisGroup.notify(queue: .main) {
                                            tempPostDetail.ancestors.sort(by: { $0.created.compare($1.created) == .orderedAscending })
                                            tempPostDetail.replies.sort(by: { $0.created.compare($1.created) == .orderedDescending })
                                            promise(.success(tempPostDetail))
                                        }
                                    }

                                }.store(in: &subscriptions)
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

    public func sendPost(content: String, image: UIImage? = nil, parent: String? = nil, url: String? = nil) -> Future<SentPost, AllesAPIErrorMessage> {
        Future<SentPost, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            var newPostConstruct: [String: String] = [
                "content": content,
            ]

            if let image = image {
                let base64Image = "data:image/jpeg;base64,\((image.jpegData(compressionQuality: 0.5)?.base64EncodedString())!)"
                newPostConstruct["image"] = "\(base64Image)"
            }

            if let parent = parent {
                newPostConstruct["parent"] = parent
            }

            if let link = url {
                if link.isValidURL, link != "" {
                    newPostConstruct["url"] = link
                }
            }

            AF.request("https://micro.alles.cx/api/posts", method: .post, parameters: newPostConstruct, encoding: JSONEncoding.prettyPrinted, headers: [
                "Authorization": authKey,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if response.response?.statusCode == 200 {
                            if responseJSON["id"].exists() {
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

            AF.request("https://micro.alles.cx/api/posts/\(id)/delete", method: .delete, parameters: nil, headers: [
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
                AF.request("https://micro.alles.cx/api/posts/\(post.id)/vote", method: .post, parameters: ["vote": value], encoding: JSONEncoding.default, headers: [
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

    public func performFollowAction(id: String, action: FollowAction) -> Future<FollowAction, AllesAPIErrorMessage> {
        Future<FollowAction, AllesAPIErrorMessage> { promise in
            guard let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") else {
                return promise(.failure(AllesAPIErrorHandler.default.returnError(error: "spica_authTokenMissing")))
            }
            AF.request("https://micro.alles.cx/api/users/\(id)/\(action.actionString)", method: .post, headers: [
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

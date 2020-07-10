//
//  Feed.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Alamofire
import Foundation
import SwiftKeychainWrapper
import SwiftyJSON
import UIKit

public class AllesAPI {
    static let `default` = AllesAPI()

    public func signInUser(username: String, password: String, completion: ((Result<SignedInUser, AllesAPIErrorMessage>) -> Void)?) {
        AF.request("https://alles.cx/api/login", method: .post, parameters: [
            "username": username,
            "password": password,
        ], encoding: JSONEncoding.default).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:
                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if responseJSON["token"].string != nil {
                            KeychainWrapper.standard.set(responseJSON["token"].string!, forKey: "dev.abmgrt.spica.user.token")
                            AllesAPI.default.loadUser(username: username) { result in
                                switch result {
                                case let .success(newUser):

                                    KeychainWrapper.standard.set(newUser.username, forKey: "dev.abmgrt.spica.user.username")
                                    KeychainWrapper.standard.set(newUser.id, forKey: "dev.abmgrt.spica.user.id")
                                    completion!(.success(SignedInUser(username: username, sessionToken: responseJSON["token"].string!)))
                                case let .failure(apiError):
                                    completion!(.failure(apiError))
                                }
                            }
                        } else {
                            completion!(.failure(.init(message: "Some values are missing, please try again", error: .unknown, actionParameter: nil, action: nil)))
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func loadFeed(completion: ((Result<[Post], AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/feed", method: .get, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        var tempPosts: [Post] = []

                        for (_, subJSON) in responseJSON["feed"] {
                            _ = subJSON["image"].string

                            tempPosts.append(Post(id: subJSON["slug"].string!, author: User(id: subJSON["author"]["id"].string!, username: subJSON["author"]["username"].string!, displayName: subJSON["author"]["name"].string!, imageURL: URL(string: "https://avatar.alles.cx/u/\(subJSON["author"]["username"])")!, isPlus: subJSON["author"]["plus"].bool!, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date.dateFromISOString(string: subJSON["createdAt"].string!)!, repliesCount: subJSON["replyCount"].intValue, score: subJSON["score"].int!, content: subJSON["content"].string!, image: UIImage(), imageURL: subJSON["image"].string != nil ? URL(string: subJSON["image"].string!) : URL(string: ""), voteStatus: subJSON["vote"].int!))
                        }
                        completion!(.success(tempPosts))

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    /*
     DispatchQueue.main.async {
     	EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { (action, index) in
     		if apiError.action != nil && apiError.actionParameter != nil {
     			if apiError.action == AllesAPIErrorAction.navigate  {
     				if apiError.actionParameter == "login" {
     					let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
     					mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: ViewController())
     						mySceneDelegate.window?.makeKeyAndVisible()

     				}
     			}
     		}
     	}
     }
     */

    /*
     if response.response?.statusCode == 200 {
     	let responseJSON = JSON(response.data!)
     	if !responseJSON["err"].exists() {

     		//custom code

     	} else {
     		let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
     		completion!(.failure(apiError))
     	}

     }
     else {
     	completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
     }
     */

    public func sendOnlineStatus() {
        var authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        if authKey == nil {
            authKey = ""
        }
        AF.request("https://online.alles.cx", method: .post, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).response(queue: .global(qos: .utility)) { _ in
            // print(String(data: response.data!, encoding: .utf8))
        }
    }

    public func loadUser(username: String, completion: ((Result<User, AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/users/\(username)", method: .get, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        AF.request("https://online.alles.cx/\(responseJSON["id"].string!)", method: .get, parameters: nil, headers: [
                            "Authorization": authKey!,
                        ]).response(queue: .global(qos: .utility)) { onlineResponse in
                            switch onlineResponse.result {
                            case .success:
                                let data = String(data: onlineResponse.data!, encoding: .utf8)
                                var isOnline: Bool!
                                if data! == "🟢" {
                                    isOnline = true
                                } else {
                                    isOnline = false
                                }
                                let newUser = User(id: responseJSON["id"].string!, username: responseJSON["username"].string!, displayName: responseJSON["name"].string!, imageURL: URL(string: "https://avatar.alles.cx/u/\(responseJSON["username"])")!, isPlus: responseJSON["plus"].bool!, rubies: responseJSON["rubies"].int!, followers: responseJSON["followers"].int!, image: UIImage(systemName: "person.circle"), isFollowing: responseJSON["following"].bool!, followsMe: responseJSON["followingUser"].bool!, about: responseJSON["about"].string!, isOnline: isOnline)
                                completion!(.success(newUser))
                            case let .failure(err):
                                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func loadUserPosts(user: User, completion: ((Result<[Post], AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/users/\(user.username)?posts", method: .get, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:
                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        var tempPosts: [Post] = []

                        DispatchQueue.global(qos: .utility).async {
                            for (_, subJSON) in responseJSON["posts"] {
                                tempPosts.append(Post(id: subJSON["slug"].string!, author: user, date: Date.dateFromISOString(string: subJSON["createdAt"].string!)!, repliesCount: subJSON["replyCount"].intValue, score: subJSON["score"].int!, content: subJSON["content"].string!, image: UIImage(systemName: "person.circle"), imageURL: subJSON["image"].string != nil ? URL(string: subJSON["image"].string!)! : URL(string: ""), voteStatus: subJSON["vote"].int!))
                            }
                            tempPosts.sort(by: { $0.date.compare($1.date) == .orderedDescending })
                            completion!(.success(tempPosts))
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func loadMentions(completion: ((Result<[Post], AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/mentions", method: .get, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        var tempPosts: [Post] = []

                        DispatchQueue.global(qos: .utility).async {
                            for (_, subJSON) in responseJSON["mentions"] {
                                tempPosts.append(Post(id: subJSON["slug"].string!, author: User(id: subJSON["author"]["id"].string!, username: subJSON["author"]["username"].string!, displayName: subJSON["author"]["name"].string!, imageURL: URL(string: "https://avatar.alles.cx/u/\(subJSON["author"]["username"].string!)")!, isPlus: subJSON["author"]["plus"].bool!, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date.dateFromISOString(string: subJSON["createdAt"].string!)!, repliesCount: subJSON["replyCount"].intValue, score: subJSON["score"].int!, content: subJSON["content"].string!, image: UIImage(), imageURL: subJSON["image"].string != nil ? URL(string: subJSON["image"].string!)! : URL(string: ""), voteStatus: subJSON["vote"].int!))
                            }
                            tempPosts.sort(by: { $0.date.compare($1.date) == .orderedDescending })
                            completion!(.success(tempPosts))
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    func loadPostDetail(postID: String, completion: ((Result<PostDetail, AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/post/\(postID)?children", method: .get, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        var tempPostDetail = PostDetail(ancestors: [], post: Post(id: "", author: User(id: "", username: "", displayName: "", imageURL: URL(string: "https://avatar.alles.cx/u/adrian")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person")!, isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date(), repliesCount: 0, score: 0, content: "", image: UIImage(systemName: "person"), voteStatus: 0), replies: [])

                        AllesAPI.default.loadUser(username: responseJSON["author"]["username"].string!) { userResult in
                            switch userResult {
                            case let .success(postUser):
                                tempPostDetail.post = Post(id: responseJSON["slug"].string!, author: postUser, date: Date.dateFromISOString(string: responseJSON["createdAt"].string!)!, repliesCount: responseJSON["replyCount"].int!, score: responseJSON["score"].int!, content: responseJSON["content"].string!, image: UIImage(), imageURL: responseJSON["image"].string != nil ? URL(string: responseJSON["image"].string!)! : URL(string: ""), voteStatus: responseJSON["vote"].int!)

                                for (_, subJSON) in responseJSON["ancestors"] {
                                    if subJSON["removed"].exists() {
                                        tempPostDetail.ancestors.append(Post(id: "removed", author: User(id: "---", username: "---", displayName: "---", imageURL: URL(string: "https://avatar.alles.cx/u/000000000000000000000000000000000000000")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date(), repliesCount: 0, score: 0, content: "Post deleted", image: UIImage(), imageURL: URL(string: ""), voteStatus: 0))
                                    } else {
                                        tempPostDetail.ancestors.append(Post(id: subJSON["slug"].string!, author: User(id: subJSON["author"]["id"].string!, username: subJSON["author"]["username"].string!, displayName: subJSON["author"]["name"].string!, imageURL: URL(string: "https://avatar.alles.cx/u/\(subJSON["author"]["username"].string!)")!, isPlus: subJSON["author"]["plus"].bool!, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date.dateFromISOString(string: subJSON["createdAt"].string!)!, repliesCount: subJSON["replyCount"].intValue, score: subJSON["score"].int!, content: subJSON["content"].string!, image: UIImage(), imageURL: subJSON["image"].string != nil ? URL(string: subJSON["image"].string!)! : URL(string: ""), voteStatus: subJSON["vote"].int!))
                                    }
                                }

                                for (_, subJSON) in responseJSON["replies"] {
                                    tempPostDetail.replies.append(Post(id: subJSON["slug"].string!, author: User(id: subJSON["author"]["id"].string!, username: subJSON["author"]["username"].string!, displayName: subJSON["author"]["name"].string!, imageURL: URL(string: "https://avatar.alles.cx/u/\(subJSON["author"]["username"].string!)")!, isPlus: subJSON["author"]["plus"].bool!, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle"), isFollowing: false, followsMe: false, about: "", isOnline: false), date: Date.dateFromISOString(string: subJSON["createdAt"].string!)!, repliesCount: subJSON["replyCount"].intValue, score: subJSON["score"].int!, content: subJSON["content"].string!, image: UIImage(), imageURL: subJSON["image"].string != nil ? URL(string: subJSON["image"].string!)! : URL(string: ""), voteStatus: subJSON["vote"].int!))
                                }

                                completion!(.success(tempPostDetail))

                            case let .failure(error):
                                completion!(.failure(error))
                            }
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func sendPost(newPost: NewPost, completion: ((Result<SentPost, AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        // TODO: Handle Image Upload

        var newPostConstruct: [String: String] = [
            "content": newPost.content,
        ]

        if newPost.image != nil {
            // let base64Image = newPost.image!.toBase64()
            let base64Image = "data:image/jpeg;base64,\((newPost.image!.jpegData(compressionQuality: 0.5)?.base64EncodedString())!)"

            newPostConstruct["image"] = "\(base64Image)"
        }

        if newPost.parent != nil {
            newPostConstruct["parent"] = newPost.parent
        }

        AF.request("https://alles.cx/api/post", method: .post, parameters: newPostConstruct, encoding: JSONEncoding.prettyPrinted, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        if responseJSON["slug"].exists() {
                            completion!(.success(SentPost(id: responseJSON["slug"].string!, username: responseJSON["username"].string!)))
                        }

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func deletePost(id: String, completion: ((Result<EmptyCompletion, AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        // TODO: Handle Image Upload

        AF.request("https://alles.cx/api/post/\(id)/remove", method: .post, parameters: nil, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        completion!(.success(.init()))

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case let .failure(err):
                completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }

    public func votePost(post: Post, value: Int, completion: ((Result<Post, AllesAPIErrorMessage>) -> Void)?) {
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        if value == -1 || value == 0 || value == 1 {
            AF.request("https://alles.cx/api/post/\(post.id)/vote", method: .post, parameters: ["vote": value], encoding: JSONEncoding.default, headers: [
                "Authorization": authKey!,
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:

                    if response.response?.statusCode == 200 {
                        let responseJSON = JSON(response.data!)
                        if !responseJSON["err"].exists() {
                            completion!(.success(post))

                        } else {
                            let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                            completion!(.failure(apiError))
                        }
                    } else {
                        completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                    }

                case let .failure(err):
                    completion!(.failure(.init(message: "An unknown error occurred: \(err.errorDescription!)", error: .unknown, actionParameter: nil, action: nil)))
                }
            }
        } else {
            completion!(.failure(AllesAPIErrorMessage(message: "The specified value is not allowed", error: .unknown, actionParameter: nil, action: nil)))
        }
    }

    public func performFollowAction(username: String, action: FollowAction, completion: ((Result<FollowAction, AllesAPIErrorMessage>) -> Void)?) {
        let actionString = action == .follow ? "follow" : "unfollow"
        let authKey = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token")
        AF.request("https://alles.cx/api/users/\(username)/\(actionString)", method: .post, headers: [
            "Authorization": authKey!,
        ]).responseJSON(queue: .global(qos: .utility)) { response in
            switch response.result {
            case .success:

                if response.response?.statusCode == 200 {
                    let responseJSON = JSON(response.data!)
                    if !responseJSON["err"].exists() {
                        completion!(.success(action))

                    } else {
                        let apiError = AllesAPIErrorHandler.default.returnError(error: responseJSON["err"].string!)
                        completion!(.failure(apiError))
                    }
                } else {
                    completion!(.failure(.init(message: "The API returned an invalid status code (Code: \(response.response!.statusCode)). Please try again.", error: .unknown, actionParameter: nil, action: nil)))
                }

            case .failure:

                completion!(.failure(.init(message: "An unknown error occurred", error: .unknown, actionParameter: nil, action: nil)))
            }
        }
    }
}

public enum FollowAction {
    case follow
    case unfollow
}

public struct EmptyCompletion {}

struct PostDetail {
    var ancestors: [Post]
    var post: Post
    var replies: [Post]
}

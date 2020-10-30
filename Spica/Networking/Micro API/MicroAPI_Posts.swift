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
import SwiftyJSON
import UIKit

extension MicroAPI {
    func loadPost(_ id: String, loadMentions: Bool = true, promise: @escaping (Result<Post, MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/posts/\(id)", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] postResponse in
            switch postResponse.result {
            case .success:
                let possibleError = isError(postResponse)
                if !possibleError.error.isError {
                    let postJSON = JSON(postResponse.data!)
                    var post: Post = .init(postJSON)
                    if loadMentions {
                        let content = post.content.replacingOccurrences(of: "\n", with: " \n ")

                        let splittedContent = content.split(separator: " ")

                        let dispatchGroup = DispatchGroup()

                        for word in splittedContent {
                            dispatchGroup.enter()
                            if String(word).starts(with: "@"), word.count > 1 {
                                let filteredWord = String(word).removeSpecialChars
                                let mentionedUserRaw = filteredWord[filteredWord.index(filteredWord.startIndex, offsetBy: 1) ..< filteredWord.endIndex]
                                loadUser(String(mentionedUserRaw)) { result in
                                    switch result {
                                    case .failure:
                                        dispatchGroup.leave()
                                    case let .success(user):
                                        post.mentionedUsers.append(user)
                                        dispatchGroup.leave()
                                    }
                                }
                            } else {
                                dispatchGroup.leave()
                            }
                        }
                        dispatchGroup.notify(queue: .main) {
                            return promise(.success(post))
                        }
                    } else {
                        return promise(.success(post))
                    }
                } else {
                    promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }

    func loadPostDetail(post: Post, promise: @escaping (Result<PostDetail, MicroError>) -> Void) {
        loadPost(post.id) { [self] result in
            switch result {
            case let .failure(err):
                return promise(.failure(err))
            case let .success(mainpost):
                var finishedPostDetail = PostDetail(ancestors: [], main: mainpost, replies: [])

                let childrenDispatchGroup = DispatchGroup()

                for child in finishedPostDetail.main.children {
                    childrenDispatchGroup.enter()

                    loadPost(child) { childResult in
                        switch childResult {
                        case let .failure(childErr):
                            childrenDispatchGroup.leave()
                            return promise(.failure(childErr))
                        case let .success(childPost):
                            finishedPostDetail.replies.append(childPost)
                            childrenDispatchGroup.leave()
                        }
                    }
                }

                childrenDispatchGroup.notify(queue: .main) {
                    let parentDispatchGroup = DispatchGroup()
                    var highestAncestor: Post? {
                        didSet {
                            if highestAncestor?.parent != nil {
                                parentDispatchGroup.enter()

                                loadPost(highestAncestor!.parent!) { ancestorResult in
                                    switch ancestorResult {
                                    case let .failure(parentErr):
                                        parentDispatchGroup.leave()
                                        return promise(.failure(parentErr))
                                    case let .success(parentPost):
                                        finishedPostDetail.ancestors.append(parentPost)
                                        highestAncestor = parentPost
                                        parentDispatchGroup.leave()
                                    }
                                }
                            }
                        }
                    }
                    highestAncestor = finishedPostDetail.main

                    parentDispatchGroup.notify(queue: .main) {
                        finishedPostDetail.ancestors.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedAscending })
                        finishedPostDetail.replies.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
                        promise(.success(finishedPostDetail))
                    }
                }
            }
        }
    }

    func sendPost(content: String, image: UIImage? = nil, parent: String? = nil, url: String? = nil, promise: @escaping (Result<Post, MicroError>) -> Void) {
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
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
            switch response.result {
            case .success:
                let possibleError = isError(response)
                if !possibleError.error.isError {
                    let responseJSON = JSON(response.data!)
                    return promise(.success(Post(responseJSON)))
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }

    func votePost(post: Post, value: Int, promise: @escaping (Result<Post, MicroError>) -> Void) {
        if value == -1 || value == 0 || value == 1 {
            AF.request("https://micro.alles.cx/api/posts/\(post.id)/vote", method: .post, parameters: ["vote": value], encoding: JSONEncoding.default, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        promise(.success(post))
                    } else {
                        return promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        } else {
            return promise(.failure(.init(error: .init(isError: true, name: "spica_valueNotAllowed"), action: nil)))
        }
    }

    func deletePost(_ id: String, promise: @escaping (Result<String, MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/posts/\(id)/delete", method: .delete, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
            switch response.result {
            case .success:
                let possibleError = isError(response)
                if !possibleError.error.isError {
                    promise(.success(id))
                } else {
                    return promise(.failure(possibleError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }
}

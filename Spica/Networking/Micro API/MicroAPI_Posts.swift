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
import SwiftyJSON
import UIKit

extension MicroAPI {
    func loadPost(_ id: String) -> Future<Post, MicroError> {
        return Future<Post, MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/posts/\(id)", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { postResponse in
                switch postResponse.result {
                case .success:
                    let possibleError = isError(postResponse)
                    if !possibleError.error.isError {
                        let postJSON = JSON(postResponse.data!)
                        return promise(.success(.init(postJSON)))
                    } else {
                        promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }

    func loadPostDetail(post: Post) -> Future<PostDetail, MicroError> {
        Future<PostDetail, MicroError> { [self] promise in
            loadPost(post.id)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        return promise(.failure(err))

                    default: break
                    }
                } receiveValue: { mainpost in
                    var finishedPostDetail = PostDetail(ancestors: [], main: mainpost, replies: [])

                    let childrenDispatchGroup = DispatchGroup()

                    for child in finishedPostDetail.main.children {
                        childrenDispatchGroup.enter()
                        loadPost(child)
                            .receive(on: RunLoop.main)
                            .sink {
                                switch $0 {
                                case let .failure(childerr):
                                    childrenDispatchGroup.leave()
                                    return promise(.failure(childerr))

                                default: break
                                }
                            } receiveValue: { childpost in
                                finishedPostDetail.replies.append(childpost)
                                childrenDispatchGroup.leave()
                            }.store(in: &subscriptions)
                    }

                    childrenDispatchGroup.notify(queue: .main) {
                        let parentDispatchGroup = DispatchGroup()
                        var highestAncestor: Post? {
                            didSet {
                                if highestAncestor?.parent != nil {
                                    parentDispatchGroup.enter()
                                    loadPost(highestAncestor!.parent!)
                                        .receive(on: RunLoop.main)
                                        .sink {
                                            switch $0 {
                                            case let .failure(parenterr):
                                                parentDispatchGroup.leave()
                                                return promise(.failure(parenterr))

                                            default: break
                                            }
                                        } receiveValue: { parentpost in
                                            finishedPostDetail.ancestors.append(parentpost)
                                            highestAncestor = parentpost
                                            parentDispatchGroup.leave()
                                        }.store(in: &subscriptions)
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

                }.store(in: &subscriptions)
        }
    }

    func sendPost(content: String, image: UIImage? = nil, parent: String? = nil, url: String? = nil) -> Future<Post, MicroError> {
        Future<Post, MicroError> { [self] promise in
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
            ]).responseJSON(queue: .global(qos: .utility)) { response in
                switch response.result {
                case .success:
                    let possibleError = isError(response)
                    if !possibleError.error.isError {
                        let responseJSON = JSON(response.data!)
                        print(responseJSON)
                        return promise(.success(Post(responseJSON)))
                    } else {
                        return promise(.failure(possibleError))
                    }
                case let .failure(err):
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                }
            }
        }
    }

    func votePost(post: Post, value: Int) -> Future<Post, MicroError> {
        Future<Post, MicroError> { [self] promise in
            if value == -1 || value == 0 || value == 1 {
                AF.request("https://micro.alles.cx/api/posts/\(post.id)/vote", method: .post, parameters: ["vote": value], encoding: JSONEncoding.default, headers: [
                    "Authorization": loadAuthKey(),
                ]).responseJSON(queue: .global(qos: .utility)) { response in
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
    }

    func deletePost(_ id: String) -> Future<String, MicroError> {
        Future<String, MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/posts/\(id)/delete", method: .delete, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { response in
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
}

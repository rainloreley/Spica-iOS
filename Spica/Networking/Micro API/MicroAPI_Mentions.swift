//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
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
    func loadMentions(promise: @escaping (Result<[Mention], MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/mentions", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] mentionResponse in
            switch mentionResponse.result {
            case .success:
                let possibleError = isError(mentionResponse)
                if !possibleError.error.isError {
                    let mentionJSON = JSON(mentionResponse.data!)
                    var errorCount = 0
                    var latestError: MicroError?
                    var mentions = [Mention]()
                    let dispatchGroup = DispatchGroup()
                    for json in mentionJSON["posts"].arrayValue {
                        dispatchGroup.enter()
                        loadPost(json["id"].string ?? "") { result in
                            switch result {
                            case let .failure(err):
                                errorCount += 1
                                latestError = err
                                dispatchGroup.leave()
                            case let .success(post):
                                mentions.append(Mention(read: json["read"].bool ?? false, post: post))
                                dispatchGroup.leave()
                            }
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        mentions.sort(by: { $0.post.createdAt.compare($1.post.createdAt) == .orderedDescending })
                        if mentions.isEmpty, errorCount > 0 {
                            promise(.failure(latestError!))
                        } else {
                            promise(.success(mentions))
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

    func markNotificationsAsRead() {
        AF.request("https://micro.alles.cx/api/mentions/read", method: .post, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON { _ in
        }
    }

    func getUnreadMentions(allowError: Bool = false, promise: @escaping (Result<[String], MicroError>) -> Void) {
        AF.request("https://micro.alles.cx/api/mentions?unread", method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] response in
            switch response.result {
            case .success:
                let possibleError = isError(response)
                if !possibleError.error.isError {
                    let mentionJSON = JSON(response.data!)
                    let mentions: [String] = mentionJSON["posts"].arrayValue.map {
                        $0["id"].stringValue
                    }
                    promise(.success(mentions))
                } else {
                    if allowError {
                        return promise(.failure(possibleError))
                    } else {
                        return promise(.success([]))
                    }
                }
            case let .failure(err):
                if allowError {
                    return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
                } else {
                    return promise(.success([]))
                }
            }
        }
    }
}

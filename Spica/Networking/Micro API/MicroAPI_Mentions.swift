//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
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

extension MicroAPI {
    func loadMentions() -> Future<[Mention], MicroError> {
        Future<[Mention], MicroError> { [self] promise in
            AF.request("https://micro.alles.cx/api/mentions", method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { mentionResponse in
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
                            print(json)
                            loadPost(json["id"].string ?? "")
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(err):
                                        errorCount += 1
                                        latestError = err
                                        dispatchGroup.leave()
                                    // promise(.failure(err))
                                    default: break
                                    }
                                } receiveValue: { post in
                                    mentions.append(Mention(read: json["read"].bool ?? false, post: post))
                                    dispatchGroup.leave()
                                }.store(in: &subscriptions)
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
    }

    func markNotificationsAsRead() {
        AF.request("https://micro.alles.cx/api/mentions/read", method: .post, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON { _ in
        }
    }
}

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

extension MicroAPI {
    func loadFeed(before: Int? = nil) -> Future<[Post], MicroError> {
        return Future<[Post], MicroError> { [self] promise in
            let url = before != nil ? "https://micro.alles.cx/api/feed?before=\(before!)" : "https://micro.alles.cx/api/feed"
            AF.request(url, method: .get, headers: [
                "Authorization": loadAuthKey(),
            ]).responseJSON(queue: .global(qos: .utility)) { feedResponse in
                switch feedResponse.result {
                case .success:
                    let possibleFeedError = isError(feedResponse)
                    if !possibleFeedError.isError {
                        let feedJSON = JSON(feedResponse.data!)
                        var feedPosts = [Post]()
                        let dispatchGroup = DispatchGroup()
                        for json in feedJSON["posts"].arrayValue {
                            dispatchGroup.enter()
                            loadPost(json.string!)
                                .receive(on: RunLoop.main)
                                .sink {
                                    switch $0 {
                                    case let .failure(err):
                                        promise(.failure(err))
                                    default: break
                                    }
                                } receiveValue: { post in
                                    feedPosts.append(post)
                                    dispatchGroup.leave()
                                }.store(in: &subscriptions)
                        }
                        dispatchGroup.notify(queue: .main) {
                            feedPosts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
                            promise(.success(feedPosts))
                        }
                    } else {
                        promise(.failure(MicroError(name: possibleFeedError.name, action: nil)))
                    }
                case let .failure(err):
                    // Implement error handling
                    return promise(.failure(MicroError(name: err.localizedDescription, action: nil)))
                }
            }
        }
    }
}

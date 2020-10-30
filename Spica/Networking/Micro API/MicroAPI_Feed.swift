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

extension MicroAPI {
    func loadFeed(before: Int? = nil, promise: @escaping (Result<[Post], MicroError>) -> Void) {
        let url = before != nil ? "https://micro.alles.cx/api/feed?before=\(before!)" : "https://micro.alles.cx/api/feed"
        AF.request(url, method: .get, headers: [
            "Authorization": loadAuthKey(),
        ]).responseJSON(queue: .global(qos: .utility)) { [self] feedResponse in
            switch feedResponse.result {
            case .success:
                let possibleFeedError = isError(feedResponse)
                if !possibleFeedError.error.isError {
                    let feedJSON = JSON(feedResponse.data!)
                    var feedPosts = [Post]()
                    var errorCount = 0
                    var latestError: MicroError?
                    let dispatchGroup = DispatchGroup()
                    for json in feedJSON["posts"].arrayValue {
                        dispatchGroup.enter()
                        loadPost(json.string ?? "") { result in
                            switch result {
                            case let .failure(err):
                                errorCount += 1
                                latestError = err
                                dispatchGroup.leave()
                            case let .success(post):
                                feedPosts.append(post)
                                dispatchGroup.leave()
                            }
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        feedPosts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
                        if feedPosts.isEmpty, errorCount > 0 {
                            promise(.failure(latestError!))
                        } else {
                            promise(.success(feedPosts))
                        }
                    }
                } else {
                    promise(.failure(possibleFeedError))
                }
            case let .failure(err):
                return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
            }
        }
    }
}

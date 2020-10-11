//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 11.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation

extension MicroAPI {
    func loadBookmarks(_ storedBookmarks: [StoredBookmark]) -> Future<[Bookmark], MicroError> {
        Future<[Bookmark], MicroError> { [self] promise in
            var finalBookmarks = [Bookmark]()
            var errorCount = 0
            var latestError: MicroError?
            let dispatchGroup = DispatchGroup()

            for bookmark in storedBookmarks {
                dispatchGroup.enter()
                loadPost(bookmark.id)
                    .receive(on: RunLoop.main)
                    .sink {
                        switch $0 {
                        case let .failure(err):
                            errorCount += 1
                            latestError = err
                            dispatchGroup.leave()
                        default: break
                        }
                    } receiveValue: { post in
                        finalBookmarks.append(.init(storedbookmark: bookmark, post: post))
                        dispatchGroup.leave()
                    }.store(in: &subscriptions)
            }

            dispatchGroup.notify(queue: .main) {
                if finalBookmarks.isEmpty, errorCount > 0 {
                    promise(.failure(latestError!))
                } else {
                    promise(.success(finalBookmarks))
                }
            }
        }
    }
}

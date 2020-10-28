//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation

public class VotePost {
    static var `default` = VotePost()

    func vote(post: Post, vote: VoteType, promise: @escaping (Result<VoteResult, MicroError>) -> Void) {
        let newVoteStatus = post.vote == vote.voteInt ? 0 : vote.voteInt

        MicroAPI.default.votePost(post: post, value: newVoteStatus) { result in
            switch result {
            case let .failure(err):
                promise(.failure(err))
            case .success:
                var newScore = post.score
                switch vote {
                case .upvote:
                    if post.vote == 1 {
                        newScore -= 1
                    } else if post.vote == 0 {
                        newScore += 1
                    } else {
                        newScore += 2
                    }
                case .downvote:
                    if post.vote == 1 {
                        newScore -= 2
                    } else if post.vote == 0 {
                        newScore -= 1
                    } else {
                        newScore += 1
                    }
                }
                promise(.success(VoteResult(score: newScore, status: newVoteStatus)))
            }
        }
    }
}

public struct VoteResult {
    var score: Int
    var status: Int
}

public enum VoteType: Hashable {
    case upvote, downvote

    var voteInt: Int {
        switch self {
        case .upvote: return 1
        case .downvote: return -1
        }
    }
}

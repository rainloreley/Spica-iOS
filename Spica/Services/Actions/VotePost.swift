//
//  VotePost.swift
//  Spica
//
//  Created by Adrian Baumgart on 14.07.20.
//

import Foundation
import Combine

public class VotePost {
	var subscriptions = Set<AnyCancellable>()
	
	static var `default` = VotePost()
	
	public func vote(post: Post, vote: VoteType) -> Future<VoteResult, AllesAPIErrorMessage> {

		return Future<VoteResult, AllesAPIErrorMessage> { [self] promise in
			let newVoteStatus = post.voteStatus == vote.voteInt ? 0 : vote.voteInt
			AllesAPI.default.votePost(post: post, value: newVoteStatus)
				.receive(on: RunLoop.main)
				.sink {
					switch $0 {
						case .failure(let err): promise(.failure(err))
						default: break
					}
				} receiveValue: { (_) in
					var newScore = post.score
					switch vote {
						case .upvote:
							if post.voteStatus == 1 {
								newScore -= 1
							}
							else if post.voteStatus == 0 {
								newScore += 1
							}
							else {
								newScore += 2
							}
						case .downvote:
							if post.voteStatus == 1 {
								newScore -= 2
							}
							else if post.voteStatus == 0 {
								newScore -= 1
							}
							else {
								newScore += 1
							}
					}
					promise(.success(VoteResult(score: newScore, status: newVoteStatus)))
				}.store(in: &subscriptions)

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

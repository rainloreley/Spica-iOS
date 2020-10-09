//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import Combine
import Alamofire
import SwiftyJSON

extension MicroAPI {
	func loadUser(_ id: String) -> Future<User, MicroError> {
		Future<User, MicroError> { [self] promise in
			AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, headers: [
						"Authorization": loadAuthKey(),
			]).responseJSON(queue: .global(qos: .utility)) { (userResponse) in
				switch userResponse.result {
					case .success:
						let possibleError = isError(userResponse)
						if !possibleError.isError {
							let userJSON = JSON(userResponse.data!)
							promise(.success(User(userJSON)))
						}
						else {
							promise(.failure(MicroError(name: possibleError.name, action: nil)))
						}
					case let .failure(err):
						return promise(.failure(MicroError(name: err.localizedDescription, action: nil)))
				}
			}
		}
	}
	
	func loadUserPosts(_ id: String) -> Future<[Post], MicroError> {
		Future<[Post], MicroError> { [self] promise in
			AF.request("https://micro.alles.cx/api/users/\(id)", method: .get, headers: [
						"Authorization": loadAuthKey(),
			]).responseJSON(queue: .global(qos: .utility)) { (response) in
				switch response.result {
					case .success:
						let possibleError = isError(response)
						if !possibleError.isError {
							let userJSON = JSON(response.data!)
							var userPosts = [Post]()
							let dispatchGroup = DispatchGroup()
							for json in userJSON["posts"]["recent"].arrayValue {
								dispatchGroup.enter()
								loadPost(json.string!)
									.receive(on: RunLoop.main)
									.sink {
										switch $0 {
											case let .failure(err):
												return promise(.failure(err))
											default: break
										}
									} receiveValue: { (userpost) in
										userPosts.append(userpost)
										dispatchGroup.leave()
									}.store(in: &subscriptions)

							}
							dispatchGroup.notify(queue: .main) {
								userPosts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
								return promise(.success(userPosts))
							}
							
						}
						else {
							promise(.failure(MicroError(name: possibleError.name, action: nil)))
						}
					case let .failure(err):
						return promise(.failure(MicroError(name: err.localizedDescription, action: nil)))
				}
			}
		}
	}
}

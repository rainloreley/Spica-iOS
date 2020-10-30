//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 30.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import Alamofire
import SwiftyJSON

extension MicroAPI {
	
	func loadUserStatus(_ id: String, promise: @escaping (Result<Status, MicroError>) -> Void) {
		AF.request("https://wassup.alles.cc/\(id)", method: .get).responseJSON(queue: .global(qos: .utility)) { [self] response in
			switch response.result {
			case .success:
				let possibleError = isError(response)
				if !possibleError.error.isError {
					let statusJSON = JSON(response.data!)
					promise(.success(.init(statusJSON)))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
	
	func updateStatus(_ content: String?, time: Int?, promise: @escaping (Result<String, MicroError>) -> Void) {
		var statusConstruct: [String: Any] = [:]

		if content != nil {
			statusConstruct["content"] = content!.trimmingCharacters(in: .whitespacesAndNewlines)
		}
		if time != nil {
			statusConstruct["time"] = time!
		}

		AF.request("https://wassup.alles.cc", method: .post, parameters: statusConstruct, encoding: JSONEncoding.prettyPrinted, headers: [
			"Authorization": loadAuthKey(),
		]).responseJSON(queue: .global(qos: .utility)) { [self] response in
			switch response.result {
			case .success:
				let possibleError = isError(response)
				if !possibleError.error.isError {
					promise(.success(content ?? ""))
				} else {
					return promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 30.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import Alamofire
import SwiftyJSON

public class FlagServerAPI {
	static let `default` = FlagServerAPI()
	
	func loadUserRing(_ id: String, promise: @escaping (Result<ProfileRing, MicroError>) -> Void) {
		AF.request("https://flag.spica.li/\(id)", method: .get).responseJSON(queue: .global(qos: .utility)) { response in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				if !possibleError.error.isError {
					let ringJSON = JSON(response.data!)
					promise(.success(ProfileRing(rawValue: ringJSON["ring"].string ?? "none") ?? .none))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}

	func updateUserRing(_ ring: ProfileRing, id: String, promise: @escaping (Result<ProfileRing, MicroError>) -> Void) {
		let userRing: [String: String] = [
			"ring": ring.rawValue,
		]
		AF.request("https://flag.spica.li/\(id)", method: .post, parameters: userRing, encoding: JSONEncoding.prettyPrinted, headers: [
			"Authorization": MicroAPI.default.loadAuthKey(),
		]).responseJSON(queue: .global(qos: .utility)) { response in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				if !possibleError.error.isError {
					let ringJSON = JSON(response.data!)
					promise(.success(ProfileRing(rawValue: ringJSON["ring"].string ?? ring.rawValue) ?? ring))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
}

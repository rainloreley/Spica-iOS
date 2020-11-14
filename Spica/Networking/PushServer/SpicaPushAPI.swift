//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 13.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import UIKit
import SwiftyJSON

public class SpicaPushAPI {
	static let `default` = SpicaPushAPI()
	
	func setDeviceTokenForSignedInUser(_ token: String, promise: @escaping (Result<String, MicroError>) -> Void) {
		AF.request("http://192.168.2.118:8080/device/create", method: .post, parameters: [
			"name": UIDevice.current.name,
			"uid": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")!,
			"token": token
		], encoding: JSONEncoding.prettyPrinted, headers: [
					"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let tokenJSON = JSON(response.data!)
				if !possibleError.error.isError {
					if let newID = tokenJSON["id"].string {
						var currentDeviceTokens = UserDefaults.standard.stringArray(forKey: "pushNotificationDeviceTokens")
						currentDeviceTokens?.append(newID)
						UserDefaults.standard.set(currentDeviceTokens, forKey: "pushNotificationDeviceTokens")
						promise(.success(newID))
					}
					else {
						promise(.failure(.init(error: .init(isError: true, name: "tokenIdNotAvailable"), action: nil)))
					}
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
}

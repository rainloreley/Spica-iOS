//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 13.11.20.
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
		
		if !UserDefaults.standard.bool(forKey: "disableTokenUploading") {
			var type = "unknown"
			
			switch UIDevice.current.userInterfaceIdiom {
				case .phone:
					type = "phone"
				case .pad:
					type = "pad"
				case .mac:
					type = "mac"
				default:
					type = "unknown"
			}
			
			#if targetEnvironment(macCatalyst)
				type = "mac"
			#endif
			AF.request("https://push.spica.li/device/create", method: .post, parameters: [
				"name": UIDevice.current.name,
				"uid": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id") ?? "",
				"token": token,
				"type": type
			], encoding: JSONEncoding.prettyPrinted, headers: [
						"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
			]).responseJSON { (response) in
				switch response.result {
				case .success:
					let possibleError = MicroAPI.default.isError(response)
					let tokenJSON = JSON(response.data!)
					if !possibleError.error.isError {
						if let newID = tokenJSON["id"].string {
							var currentDeviceTokens = UserDefaults.standard.stringArray(forKey: "pushNotificationDeviceTokens") ?? []
							currentDeviceTokens.append(newID)
							UserDefaults.standard.set(Array(Set(currentDeviceTokens)), forKey: "pushNotificationDeviceTokens")
							UserDefaults.standard.set(newID, forKey: "pushNotificationCurrentDevice")
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
		else {
			promise(.success(""))
		}
	}
	
	func getUserData(promise: @escaping (Result<PushUser, MicroError>) -> Void) {
		AF.request("https://push.spica.li/user", method: .get, headers: [
			"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let userJSON = JSON(response.data!)
				if !possibleError.error.isError {
					promise(.success(.init(userJSON)))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
	
	func updateUserData(notificationsEnabled: Bool, repliesEnabled: Bool, mentionsEnabled: Bool, promise: @escaping (Result<PushUser, MicroError>) -> Void) {
		AF.request("https://push.spica.li/user/update", method: .post, parameters: [
			"notificationsEnabled": notificationsEnabled,
			"repliesEnabled": repliesEnabled,
			"mentionsEnabled": mentionsEnabled
		], encoding: JSONEncoding.prettyPrinted, headers: [
					"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let userJSON = JSON(response.data!)
				if !possibleError.error.isError {
					promise(.success(.init(userJSON)))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
	
	func deleteDevices(_ devices: [String], promise: @escaping (Result<JSON, MicroError>) -> Void) {
		AF.request("https://push.spica.li/device/delete", method: .delete, parameters: [
			"devices": devices
		], encoding: JSONEncoding.prettyPrinted, headers: [
					"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let json = JSON(response.data!)
				if !possibleError.error.isError {
					promise(.success(json))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
	
	func revokeAllDevices(promise: @escaping (Result<JSON, MicroError>) -> Void) {
		AF.request("https://push.spica.li/user/revokeall", method: .post, headers: [
			"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let json = JSON(response.data!)
				if !possibleError.error.isError {
					promise(.success(json))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
	
	func deleteUser(promise: @escaping (Result<JSON, MicroError>) -> Void) {
		AF.request("https://push.spica.li/user/delete", method: .delete, headers: [
			"Authorization": KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.token") ?? ""
		]).responseJSON { (response) in
			switch response.result {
			case .success:
				let possibleError = MicroAPI.default.isError(response)
				let json = JSON(response.data!)
				if !possibleError.error.isError {
					UserDefaults.standard.set(false, forKey: "disableTokenUploading")
					promise(.success(json))
				} else {
					promise(.failure(possibleError))
				}
			case let .failure(err):
				return promise(.failure(.init(error: .init(isError: true, name: err.localizedDescription), action: nil)))
			}
		}
	}
}

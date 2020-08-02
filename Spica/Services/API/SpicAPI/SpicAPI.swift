//
//  SpicAPI.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import Alamofire
import Foundation
import SwiftyJSON
import UIKit
import Combine

public class SpicAPI {
	
	public static func getVersion() -> Future<Version, Error> {
		Future<Version, Error> { promise in
			AF.request("https://api.spica.fliney.eu/apps/ios/version", method: .get).responseJSON { (response) in
				switch response.result {
					case .success:
						let responseJSON = JSON(response.data!)
						promise(.success(Version(reqVersion: responseJSON["required"]["version"].string!, reqBuild: responseJSON["required"]["build"].int!, newVersion: responseJSON["newest"]["version"].string!, newBuild: responseJSON["newest"]["build"].int!)))
					case let .failure(error):
						promise(.failure(error.underlyingError!))
				}
			}
		}
	}
	
	public static func getPrivacyPolicy() -> Future<PrivacyPolicy, Error> {
		Future<PrivacyPolicy, Error> { promise in
			AF.request("https://api.spica.fliney.eu/privacy", method: .get).responseJSON { (response) in
				switch response.result {
					case .success:
						let responseJSON = JSON(response.data!)
						if UserDefaults.standard.integer(forKey: "spica_privacy_accepted_version") < responseJSON["updated"].int! {
							AF.request(responseJSON["url"].string! as URLConvertible, method: .get).responseString { (response2) in
								switch response2.result {
									case .success:
										return promise(.success(PrivacyPolicy(updated: responseJSON["updated"].int!, markdown: String(data: response2.data!, encoding: .utf8)!)))
									case let .failure(error):
										return promise(.failure(error.underlyingError!))
								}
							}
						}
						else {
							return promise(.success(PrivacyPolicy(updated: responseJSON["updated"].int!, markdown: "")))
						}
					case let .failure(error):
						return promise(.failure(error.underlyingError!))
				}
			}
		}
	}
	
	public struct Version {
		var reqVersion: String
		var reqBuild: Int
		
		var newVersion: String
		var newBuild: Int
	}
}

public struct PrivacyPolicy {
	var updated: Int
	var markdown: String
}

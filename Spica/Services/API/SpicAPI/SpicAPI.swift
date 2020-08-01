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
	
	public struct Version {
		var reqVersion: String
		var reqBuild: Int
		
		var newVersion: String
		var newBuild: Int
	}
}



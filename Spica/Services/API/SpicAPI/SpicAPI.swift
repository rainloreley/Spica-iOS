//
//  SpicAPI.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import Alamofire
import Combine
import Foundation
import SwiftyJSON
import UIKit

public class SpicAPI {
    static let `default` = SpicAPI()
    public static func getVersion() -> Future<Version, Error> {
        Future<Version, Error> { promise in
            AF.request("https://api.spica.li/apps/ios/version", method: .get).responseJSON { response in
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

    public static func getLabels(_ labels: [String]) -> Future<[Label], AllesAPIErrorMessage> {
        Future<[Label], AllesAPIErrorMessage> { promise in
            let body: [String: Any] = [
                "labels": labels,
            ]
            AF.request("https://api.spica.li/label", method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json; charset=utf-8"]).responseJSON { response in
                switch response.result {
                case .success:
                    if response.response?.statusCode == 200 {
                        let responseJSON = JSON(response.data!)
                        let tempLabels = responseJSON["success"].map { _, json in
                            Label(json)
                        }
                        promise(.success(tempLabels))
                    } else {
                        promise(.failure(AllesAPIErrorMessage(message: "Invalid status code", error: .unknown, actionParameter: "", action: .none)))
                    }
                case let .failure(error):
                    promise(.failure(AllesAPIErrorMessage(message: error.underlyingError!.localizedDescription, error: .unknown, actionParameter: "", action: .none)))
                }
            }
        }
    }

    public static func getPrivacyPolicy() -> Future<PrivacyPolicy, Error> {
        Future<PrivacyPolicy, Error> { promise in
            AF.request("https://api.spica.li/privacy", method: .get).responseJSON { response in
                switch response.result {
                case .success:
                    let responseJSON = JSON(response.data!)
                    if UserDefaults.standard.integer(forKey: "spica_privacy_accepted_version") < responseJSON["updated"].int! {
                        AF.request(responseJSON["url"].string! as URLConvertible, method: .get).responseString { response2 in
                            switch response2.result {
                            case .success:
                                return promise(.success(PrivacyPolicy(updated: responseJSON["updated"].int!, markdown: String(data: response2.data!, encoding: .utf8)!)))
                            case let .failure(error):
                                return promise(.failure(error.underlyingError!))
                            }
                        }
                    } else {
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

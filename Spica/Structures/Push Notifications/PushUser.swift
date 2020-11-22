//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 14.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftyJSON

struct PushUser {
	var id: String
	var notificationsEnabled: Bool
	var repliesEnabled: Bool
	var mentionsEnabled: Bool
	var devices: [PushDevice]
	var usersSubscribedTo: [User]
	
	init(_ json: JSON) {
		id = json["id"].string ?? ""
		notificationsEnabled = json["notificationsEnabled"].bool ?? true
		repliesEnabled = json["repliesEnabled"].bool ?? true
		mentionsEnabled = json["mentionsEnabled"].bool ?? true
		devices = json["devices"].arrayValue.map { json in
			return PushDevice(json)
		}
		usersSubscribedTo = json["userpushsubscriptions"].arrayValue.map { json in
			return User(id: json["subscribedto"].string ?? "")
		}
	}
}

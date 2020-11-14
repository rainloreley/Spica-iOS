//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 14.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftUI
import Combine

class NotificationSettingsController: ObservableObject {
	
	@Published var finishedInitialLoading: Bool = false
	
	@Published var notificationsEnabled: Bool = true {
		didSet {
			if finishedInitialLoading {
				updateSettings(changedValue: "notifications")
			}
		}
	}
	
	@Published var repliesEnabled: Bool = true {
		didSet {
			if finishedInitialLoading {
				updateSettings(changedValue: "replies")
			}
		}
	}
	
	@Published var mentionsEnabled: Bool = true {
		didSet {
			if finishedInitialLoading {
				updateSettings(changedValue: "mentions")
			}
		}
	}
	
	@Published var devices = [PushDevice]()
	
	@Published var allowTokenUploading: Bool = true {
		didSet {
			if finishedInitialLoading {
				UserDefaults.standard.set(!allowTokenUploading, forKey: "disableTokenUploading")
			}
		}
	}
	
	@Published var showErrorMessage: Bool = false
	
	@Published var microError: MicroError?
	
	func updateSettings(changedValue: String) {
		SpicaPushAPI.default.updateUserData(notificationsEnabled: notificationsEnabled, repliesEnabled: repliesEnabled, mentionsEnabled: mentionsEnabled) { [self] (result) in
			switch result {
				case let .failure(err):
					finishedInitialLoading = false
					switch changedValue {
						case "mentions":
							mentionsEnabled = !mentionsEnabled
						case "replies":
							repliesEnabled = !repliesEnabled
						case "notifications":
							notificationsEnabled = !notificationsEnabled
						default: break
							
					}
					finishedInitialLoading = true
					microError = err
					showErrorMessage = true
				case let .success(user):
					finishedInitialLoading = false
					notificationsEnabled = user.notificationsEnabled
					repliesEnabled = user.repliesEnabled
					mentionsEnabled = user.mentionsEnabled
					devices = user.devices
					finishedInitialLoading = true
					
			}
		}
	}
	
	func fetchInformation() {
		finishedInitialLoading = false
		allowTokenUploading = !UserDefaults.standard.bool(forKey: "disableTokenUploading")
		SpicaPushAPI.default.getUserData { [self] (result) in
			switch result {
				case let .failure(err):
					microError = err
					showErrorMessage = true
				case let .success(user):
					notificationsEnabled = user.notificationsEnabled
					repliesEnabled = user.repliesEnabled
					mentionsEnabled = user.mentionsEnabled
					devices = user.devices
					finishedInitialLoading = true
					
			}
		}
	}
	
	func revokeDevice(_ device: PushDevice) {
		SpicaPushAPI.default.deleteDevices([device.id]) { [self] (result) in
			switch result {
				case let .failure(err):
					microError = err
					showErrorMessage = true
				case .success:
					fetchInformation()
			}
		}
	}
	
	func requestNewToken() {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		appDelegate.registerForPushNotifications()
	}
	
	func revokeAll() {
		SpicaPushAPI.default.revokeAllDevices() { [self] (result) in
			switch result {
				case let .failure(err):
					microError = err
					showErrorMessage = true
				case .success:
					fetchInformation()
			}
		}
	}
}

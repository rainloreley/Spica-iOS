//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 28.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftKeychainWrapper
import SwiftUI
import LocalAuthentication

protocol SettingsDelegate {
	func signedOut()
	func setBiomicSessionToAuthorized()
	func overrideUIInterfaceStyle(_ style: UIUserInterfaceStyle)
}

class SettingsController: ObservableObject {
	
	@Published var signedInId: String = ""
	@Published var signedInName: String = ""
	@Published var signedInTag: String = ""
	@Published var versionText: String = ""
	@Published var showLoadingIndicator: Bool = false
	
	var isLoadingInformation: Bool = true
	
	@Published var showProfileFlagOnPost: Bool = false {
		didSet {
			if !isLoadingInformation {
				UserDefaults.standard.set(!showProfileFlagOnPost, forKey: "disablePostFlagLoading")
			}
		}
	}
	
	@Published var rickrollDetection: Bool = false {
		didSet {
			if !isLoadingInformation {
				UserDefaults.standard.set(!rickrollDetection, forKey: "rickrollDetectionDisabled")
			}
		}
	}
	
	@Published var biometricAuthEnabled: Bool = false {
		didSet {
			if !isLoadingInformation {
				if biometricAuthEnabled == false {
					UserDefaults.standard.set(biometricAuthEnabled, forKey: "biometricAuthEnabled")
				}
				else {
					let authContext = LAContext()
					var authError: NSError?

					if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
						UserDefaults.standard.set(biometricAuthEnabled, forKey: "biometricAuthEnabled")
						delegate.setBiomicSessionToAuthorized()
						//SPAlert.present(title: "Biometric authentication \(biometricSwitch.isOn ? String("enabled") : String("disabled"))!", preset: .done)
					} else {
						delegate.setBiomicSessionToAuthorized()
						DispatchQueue.main.async { [self] in
							isLoadingInformation = true
							biometricAuthEnabled = false
							isLoadingInformation = false
						}
						UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")

						var type = "FaceID / TouchID"
						let biometric = biometricType()
						switch biometric {
						case .face:
							type = "FaceID"
						case .touch:
							type = "TouchID"
						case .none:
							type = "FaceID / TouchID"
						}
						EZAlertController.alert("Device error", message: String(format: "\(type) is not enrolled on your device. Please verify it's enabled in your devices' settings"))
					}
				}
			}
		}
	}
	
	@Published var biometricAuthAllowed: Bool = false
	
	@Published var imageCompressionTag: Int = 2 {
		didSet {
			if !isLoadingInformation {
				switch imageCompressionTag {
					case 0: // Best
						UserDefaults.standard.set(1, forKey: "imageCompressionValue")
					case 1: // Good
						UserDefaults.standard.set(0.75, forKey: "imageCompressionValue")
					case 2: // Normal
						UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
					case 3: // Bad
						UserDefaults.standard.set(0.25, forKey: "imageCompressionValue")
					default:
						UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
				}
			}
		}
	}
	
	@Published var appUISettingTag: UserInterfaceSetting = .auto {
		didSet {
			if !isLoadingInformation {
				UserDefaults.standard.set(appUISettingTag.rawValue, forKey: "userInterfaceSetting")
				delegate.overrideUIInterfaceStyle(appUISettingTag.uiInterfaceStyle())
			}
		}
	}
	
	
	var delegate: SettingsDelegate!
	var colorDelegate: ColorPickerControllerDelegate!
	
	
	let colorPickerController: ColorPickerController!
	
	init(delegate: SettingsDelegate, colorDelegate: ColorPickerControllerDelegate) {
		self.delegate = delegate
		self.colorDelegate = colorDelegate
		
		let currentAccentColor = UserDefaults.standard.colorForKey(key: "globalTintColor")
		colorPickerController = ColorPickerController(color: Color(currentAccentColor ?? UIColor.systemBlue))
		colorPickerController.delegate = colorDelegate
	}
	
	func loadInfo() {
		isLoadingInformation = true
		
		signedInId = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id") ?? "_"
		signedInName = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.name") ?? ""
		signedInTag = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.tag") ?? ""
		
		let dictionary = Bundle.main.infoDictionary!
		let version = dictionary["CFBundleShortVersionString"] as! String
		let build = dictionary["CFBundleVersion"] as! String

		versionText = "Version \(version) Build \(build)"
		
		showProfileFlagOnPost = !UserDefaults.standard.bool(forKey: "disablePostFlagLoading")
		rickrollDetection = !UserDefaults.standard.bool(forKey: "rickrollDetectionDisabled")
		biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
		appUISettingTag = UserInterfaceSetting.init(rawValue: UserDefaults.standard.string(forKey: "userInterfaceSetting") ?? "auto") ?? .auto
		
		let authContext = LAContext()
		var authError: NSError?
		if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
			biometricAuthAllowed = true
		} else {
			biometricAuthAllowed = false
		}
		
		let savedImageCompression = UserDefaults.standard.double(forKey: "imageCompressionValue")
		if savedImageCompression == 0 {
			UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
			imageCompressionTag = 2
		}
		else {
			switch savedImageCompression {
				case 0.25:
					imageCompressionTag = 3
				case 0.5:
					imageCompressionTag = 2
				case 0.75:
					imageCompressionTag = 1
				case 1:
					imageCompressionTag = 0
				default:
					UserDefaults.standard.set(0.5, forKey: "imageCompressionValue")
					imageCompressionTag = 2
			}
		}
		
		isLoadingInformation = false
	}
	
	func signOut() {
		showLoadingIndicator = true

		var storedDeviceTokens = UserDefaults.standard.stringArray(forKey: "pushNotificationDeviceTokens") ?? []
		storedDeviceTokens.append(UserDefaults.standard.string(forKey: "pushNotificationCurrentDevice") ?? "")
		SpicaPushAPI.default.deleteDevices(storedDeviceTokens) { [self] result in
			switch result {
			case let .failure(err):
				showLoadingIndicator = false
				EZAlertController.alert("Error", message: "The following error occurred while trying to revoke the push device tokens:\n\n\(err.error.humanDescription)")
			case .success:
				let domain = Bundle.main.bundleIdentifier!
				UserDefaults.standard.removePersistentDomain(forName: domain)
				UserDefaults.standard.synchronize()
				KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.name")
				KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.tag")
				KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.token")
				KeychainWrapper.standard.removeObject(forKey: "dev.abmgrt.spica.user.id")
				UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
				showLoadingIndicator = true
				delegate.signedOut()
				/*let sceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
				sceneDelegate.window?.rootViewController = sceneDelegate.loadInitialViewController()
				sceneDelegate.window?.makeKeyAndVisible()*/
			}
		}
	}
}

enum UserInterfaceSetting: String {
	case auto
	case dark
	case light
	
	func uiInterfaceStyle() -> UIUserInterfaceStyle {
		switch self {
			case .auto:
				return .unspecified
			case .dark:
				return .dark
			case .light:
				return .light
		}
	}
}

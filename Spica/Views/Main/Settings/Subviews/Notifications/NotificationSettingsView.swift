//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 14.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI
import KingfisherSwiftUI

struct NotificationSettingsView: View {
	
	@ObservedObject var controller: NotificationSettingsController
	
    var body: some View {
		Group {
			if controller.finishedInitialLoading {
				if controller.pushaccountexists {
					if #available(iOS 14.0, *) {
						List {
							NotificationSettingsListView(controller: controller)
						}.listStyle(InsetGroupedListStyle())
					} else {
						List {
							NotificationSettingsListView(controller: controller)
						}.listStyle(GroupedListStyle())
						.environment(\.horizontalSizeClass, .regular)
					}
				}
				else {
					Text("There's currently no user record in our database. Please enable push notifications within your devices' settings and relaunch the app")
				}
			}
			else {
				VStack {
					Text("Loading information...")
					ActivityIndicator(isAnimating: .constant(true), style: .large)
				}
			}
		}.navigationBarTitle(Text("Notifications"))
		.navigationBarItems(trailing: Button(action: {
			controller.fetchInformation()
		}, label: {
			Image(systemName: "arrow.clockwise")
		}))
		.onAppear(perform: {
			controller.fetchInformation()
		}).alert(isPresented: $controller.showErrorMessage) {
			Alert(title: Text("Error"), message: Text("The following error occurred:\n\(controller.microError!.error.humanDescription)"), dismissButton: .cancel())
		}
    }
}

struct NotificationSettingsListView: View {
	
	@ObservedObject var controller: NotificationSettingsController
	@Environment(\.presentationMode) var mode: Binding<PresentationMode>
	
	var body: some View {
		Section(header: Text("All Notifications"), footer: Text("This setting applies to your AllesID, not every device individually.")) {
			Group {
				Toggle(isOn: $controller.notificationsEnabled, label: {
					Text("Notifications")
				})
			}
		}
		Section(header: Text("Individual settings"), footer: Text("These settings apply to your AllesID, not every device individually.")) {
			Toggle(isOn: $controller.repliesEnabled, label: {
				Text("Replies")
			})
			Toggle(isOn: $controller.mentionsEnabled, label: {
				Text("Mentions")
			})
			NavigationLink(
				destination: SubscriptionsDetailView(controller: controller),
				label: {
					Text("Posts by users (\(controller.subscribedUsers.count))")
				})
		}
		
		Section(header: Text("Devices")) {
			if controller.devices.count > 0 {
				ForEach(controller.devices) { (device) in
					HStack {
						VStack(alignment: .leading) {
							if device.id == UserDefaults.standard.string(forKey: "pushNotificationCurrentDevice") {
								Text(device.name).bold() + Text(" (This device)").italic().foregroundColor(.secondary)
							}
							else {
								Text(device.name).bold()
							}
							switch device.type {
								case .phone:
									Text("iPhone").foregroundColor(.secondary)
								case .pad:
									Text("iPad").foregroundColor(.secondary)
								case .mac:
									Text("Mac").foregroundColor(.secondary)
								default:
									Text("Unknown device").foregroundColor(.secondary)
							}
							
							Text("Added: \(RelativeDateTimeFormatter().localizedString(for: device.created, relativeTo: Date()))").foregroundColor(.secondary)
							
						}.padding(4)
						Spacer()
						Button(action: {
							controller.revokeDevice(device)
						}, label: {
							Text("Revoke").foregroundColor(.red)
						})
						
					}
				}
			}
			else {
				Text("No devices registered").italic()
			}
		}
		
		Section(footer: Text("Disabling this setting prevents the app from uploading new device tokens for this device. You might still receive push notifications until you revoke the device.")) {
			Toggle(isOn: $controller.allowTokenUploading) {
				Text("Allow token uploading")
			}
		}
		
		Section(footer: Text("This will request a device token from the device and upload it to our server")) {
			Button(action: {
				controller.requestNewToken()
			}, label: {
				Text("Request and upload token")
			})
		}
		Section(footer: Text("This will remove all devices from your account. If you relaunch the app, the device token will be stored again.")) {
			Button(action: {
				controller.revokeAll()
			}, label: {
				Text("Revoke all devices").foregroundColor(.red)
			})
		}
		Section(footer: Text("Delete all user data from the push server. It'll also reset the notification settings. If you relaunch the app, the device token will be stored and again.")) {
			Button(action: {
				SpicaPushAPI.default.deleteUser() { [self] (result) in
					switch result {
						case let .failure(err):
							controller.microError = err
							controller.showErrorMessage = true
						case .success:
							mode.wrappedValue.dismiss()
							
					}
				}
			}, label: {
				Text("Delete user data").foregroundColor(.red)
			})
		}
		
		
	}
}

struct SubscriptionsDetailView: View {
	
	@ObservedObject var controller: NotificationSettingsController
	
	var body: some View {
		Group {
			if #available(iOS 14.0, *) {
				List {
					SubscriptionsDetailViewList(controller: controller)
				}.listStyle(InsetGroupedListStyle())
			} else {
				List {
					SubscriptionsDetailViewList(controller: controller)
				}.listStyle(GroupedListStyle())
				.environment(\.horizontalSizeClass, .regular)
			}
		}.navigationBarTitle(Text("Users"))
	}
}

struct SubscriptionsDetailViewList: View {
	
	@ObservedObject var controller: NotificationSettingsController
	
	var body: some View {
		ForEach(controller.subscribedUsers) { subscription in
			HStack {
				KFImage(subscription.profilePictureUrl)
					.resizable().frame(width: 40, height: 40, alignment: .leading).cornerRadius(20)
				VStack(alignment: .leading) {
					Text("\(subscription.name)").bold()
					Text("\(subscription.name)#\(subscription.tag)").foregroundColor(.secondary)
				}
				Spacer()
			}.padding(6)
			.onTapGesture {
				UIApplication.shared.open(URL(string: "spica://user/\(subscription.id)")!)
			}
		}
	}
}

struct ActivityIndicator: UIViewRepresentable {

	@Binding var isAnimating: Bool
	let style: UIActivityIndicatorView.Style

	func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
		return UIActivityIndicatorView(style: style)
	}

	func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
		isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
	}
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			NotificationSettingsView(controller: .init())
		}
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 28.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI
import KingfisherSwiftUI
import class Kingfisher.ImageCache
import SPAlert

struct SettingsView: View {
	
	@ObservedObject var controller: SettingsController
	@State var showChangeAccentColorSheet: Bool = false
	
	@Environment(\.colorScheme) var colorScheme
	
    var body: some View {
		GeometryReader(content: { geometry in
			ZStack {
				Group {
					if #available(iOS 14.0, *) {
						List {
							SettingsSubView(controller: controller, showChangeAccentColorSheet: $showChangeAccentColorSheet)
						}.listStyle(InsetGroupedListStyle())
						.simultaneousGesture(DragGesture().onChanged({ _ in
							if showChangeAccentColorSheet {
								withAnimation {
									showChangeAccentColorSheet.toggle()
								}
							}
						}))
					} else {
						List {
							SettingsSubView(controller: controller, showChangeAccentColorSheet: $showChangeAccentColorSheet)
						}.listStyle(GroupedListStyle())
							.environment(\.horizontalSizeClass, .regular)
						.simultaneousGesture(DragGesture().onChanged({ _ in
							if showChangeAccentColorSheet {
								withAnimation {
									showChangeAccentColorSheet.toggle()
								}
							}
						}))
					}
				}
				Group {
					ZStack {
						VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .dark : .light)).frame(width: geometry.size.width, height: 200, alignment: .center)
						VStack {
							HStack {
								Spacer()
								Text("Change accent color").foregroundColor(.secondary)
								Spacer()
								Button(action: {
									withAnimation {
										showChangeAccentColorSheet.toggle()
									}
								}, label: {
									Image(systemName: "xmark.circle.fill").foregroundColor(.gray).imageScale(.large).padding(.trailing)
								})
							}.padding(.top)
							ColorPickerView(controller: controller.colorPickerController)
						}.padding()
					}
				}.frame(width: geometry.size.width - 32, height: 200, alignment: .center).cornerRadius(12).background(Color.clear)
				.edgesIgnoringSafeArea(.all)
				.offset(x: 0, y: showChangeAccentColorSheet ? (UIScreen.main.bounds.height / 2) - 200 : UIScreen.main.bounds.height)
				if controller.showLoadingIndicator {
					Group {
						VStack {
							ActivityIndicator(isAnimating: .constant(true), style: .large)
							Text("Loading").bold()
						}
					}.frame(width: 180, height: 180, alignment: .center)
						.background(Color(UIColor.secondarySystemBackground).opacity(0.3))
						.cornerRadius(20)
				}
			}.onAppear(perform: {
				controller.loadInfo()
			}).navigationBarTitle(Text("Settings"), displayMode: .automatic)
		}).navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsSubView: View {
	
	@ObservedObject var controller: SettingsController
	
	@Binding var showChangeAccentColorSheet: Bool
	
	
	var body: some View {
		Section(header: Text("Account"), footer: Text("Signing out will remove this device from push notifications for Spica, reset all app settings and clear all user-related data.").padding([.leading, .bottom, .trailing], 8).padding(.top, 4)) {
			HStack {
				KFImage(URL(string: "https://avatar.alles.cc/\(controller.signedInId)")!).resizable().frame(width: 50, height: 50, alignment: .center).clipShape(Circle())
				Text("\(controller.signedInName)#\(controller.signedInTag)")
			}.padding(4)
			Button(action: {
				controller.signOut()
			}, label: {
				Text("Sign out").bold().foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: 20, alignment: .center).padding().background(Color.red).cornerRadius(12).padding(4)
			})
		}
		
		Section(header: Text("Settings"), footer: Text("Enabling \"Show profile flag on post\" will show the profile flag around the profile picture in a post but will also increase the time to load").padding([.leading, .bottom, .trailing], 8).padding(.top, 4)) {
			Toggle(isOn: $controller.biometricAuthEnabled, label: {
				SettingsSideIcon(image: "faceid", text: "Biometrics")
			}).padding(4).disabled(!controller.biometricAuthAllowed)
			Button(action: {
				withAnimation {
					showChangeAccentColorSheet.toggle()
				}
			}, label: {
				SettingsSideIcon(image: "eyedropper", text: "Change accent color")
			})
			Button(action: {
				Kingfisher.ImageCache.default.clearCache {
					SPAlert.present(title: "Cache cleared!", preset: .done)
				}
			}, label: {
				SettingsSideIcon(image: "trash", text: "Clear cache", colorOverride: .red, isButton: true)
			}).padding(4)
			NavigationLink(
				destination: SelectFlagView(),
				label: {
					SettingsSideIcon(image: "flag", text: "Change profile picture flag")
				}).padding(4)
			Toggle(isOn: $controller.showProfileFlagOnPost, label: {
				SettingsSideIcon(image: "square.and.arrow.down", text: "Show profile flag on post")
			}).padding(4)
			Toggle(isOn: $controller.rickrollDetection, label: {
				SettingsSideIcon(image: "exclamationmark.triangle", text: "Rickroll detection")
			}).padding(4)
			NavigationLink(
				destination: NotificationSettingsView(controller: .init()),
				label: {
					SettingsSideIcon(image: "app.badge", text: "Notification settings")
				}).padding(4)
			VStack(alignment: .leading, spacing: nil) {
				SettingsSideIcon(image: "rectangle.compress.vertical", text: "Image quality (compression)")
				Picker(selection: $controller.imageCompressionTag, label: Text(""), content: {
					Text("Best").tag(0)
					Text("Good").tag(1)
					Text("Normal").tag(2)
					Text("Bad").tag(3)
				}).pickerStyle(SegmentedPickerStyle())
			}.padding(4)
		}
		
		Section(header: Text("Spica")) {
			Button(action: {
				let url = URL(string: "https://spica.li/privacy")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "lock", text: "Privacy Policy", isButton: true)
			})
			NavigationLink(
				destination: LegalNoticeView(),
				label: {
					SettingsSideIcon(image: "briefcase", text: "Legal notice")
				})
			Button(action: {
				let url = URL(string: "https://spica.li/")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "globe", text: "Website", isButton: true)
			})
		}
		
		Section(header: Text("Alles Micro")) {
			Button(action: {
				let url = URL(string: "https://files.alles.cc/Documents/Privacy%20Policy.txt")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "lock", text: "Privacy Policy", isButton: true)
			})
			Button(action: {
				let url = URL(string: "https://files.alles.cc/Documents/Terms%20of%20Service.txt")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "briefcase", text: "Terms of Service", isButton: true)
			})
			Button(action: {
				let url = URL(string: "https://micro.alles.cx/")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "globe", text: "Website", isButton: true)
			})
		}
		
		Section(header: Text("Other")) {
			NavigationLink(
				destination: UsedLibrariesView(),
				label: {
					SettingsSideIcon(image: "tray", text: "Used Libraries")
				})
			NavigationLink(
				destination: CreditsView(),
				label: {
					SettingsSideIcon(image: "star", text: "Credits")
				})
			Button(action: {
				let url = URL(string: "https://github.com/SpicaApp/Spica-iOS")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "chevron.left.slash.chevron.right", text: "GitHub")
			})
			Button(action: {
				let url = URL(string: "mailto:lea@abmgrt.dev")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "envelope", text: "Contact")
			})
			Button(action: {
				let url = URL(string: "https://go.abmgrt.dev/spica-beta")!
				if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
			}, label: {
				SettingsSideIcon(image: "sparkles", text: "Join the beta")
			})
		}
		
		Section(header: Text("About")) {
			Text("\(controller.versionText)").foregroundColor(.secondary).font(.footnote)
			Text("© 2020, Lea Baumgart. All rights reserved.").foregroundColor(.secondary).font(.footnote)
		}
	}
}

struct SettingsSideIcon: View {
	var image: String
	var text: String
	var colorOverride: Color? = nil
	var isButton: Bool = false
	
	var body: some View {
		HStack {
			Image(systemName: image).resizable().aspectRatio(contentMode: .fit).frame(width: 22, height: 22, alignment: .leading)
			Text(text).font(.callout)
		}.foregroundColor(isButton ? colorOverride ?? .accentColor : .accentColor)
	}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
		SettingsSideIcon(image: "faceid", text: "Text")
    }
}

struct VisualEffectView: UIViewRepresentable {
	var effect: UIVisualEffect?
	func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
	func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

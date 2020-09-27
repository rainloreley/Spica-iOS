//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 01.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SkeletonUI
import SwiftUI
import Lightbox

struct UserHeaderView: View {
    @ObservedObject var controller: UserHeaderViewController

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM dd, yyyy", options: 0, locale: Locale.current) // "MMM dd, yyyy HH:mm"
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    Image(uiImage: controller.user.image ?? UIImage(systemName: "person.circle"))
                        .resizable()
                        .frame(width: 120, height: 120, alignment: .center)
                        .clipShape(Circle())
                        .shadow(radius: 10)

                        .overlay(Circle()

                            .trim(from: 0, to: controller.grow ? 1 : 0)
                            .stroke(controller.user.isOnline ? Color.green : Color.gray, lineWidth: 4)
                            .rotationEffect(.degrees(90), anchor: .center)
                            .animation(.easeInOut(duration: 1))
                            .shadow(radius: 8)
                        )
						.gesture(
							TapGesture().onEnded({ (_) in
								//presentPfpFullscreen = true
								controller.delegate.clickedPfp(image: controller.user.image)
							}))
                }
                Spacer()
            }
            Group {
                HStack {
                    Text("\(controller.user.nickname)\(controller.user.plus ? String("⁺") : String(""))").font(.title).bold()
                    /*if !controller.user.alles {
                        Text("Bot").foregroundColor(.white).font(.subheadline)
                            .padding(6)
                            .background(Color("PostButtonColor"))
                            .cornerRadius(12)
                    }*/
                }
                Text("\(controller.user.name)#\(controller.user.tag)").foregroundColor(.secondary)
                if controller.user.followsMe && !controller.isLoggedInUser {
                    Text(SLocale(.FOLLOWS_YOU)).foregroundColor(.init(UIColor.tertiaryLabel))
                }
				
                HStack {
                    Group {
                        if controller.isLoggedInUser {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Button(action: {
                                    controller.showFollowers()
                                }, label: {
                                    Text("\(controller.user.followers) ").bold() + Text(countString(number: controller.user.followers, singleText: SLocale(.FOLLOWER_SINGULAR), multiText: SLocale(.FOLLOWER_PLURAL), includeNumber: false))

								})
                            }
                        } else {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Text("\(controller.user.followers) ").bold() + Text(countString(number: controller.user.followers, singleText: SLocale(.FOLLOWER_SINGULAR), multiText: SLocale(.FOLLOWER_PLURAL), includeNumber: false))
                            }
                        }
                    }.padding(.trailing)
                        .foregroundColor(Color(UIColor.label))

                    Group {
                        if controller.isLoggedInUser {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Button(action: {
                                    controller.showFollowing()
                                }, label: {
                                    Text("\(controller.user.following) ").bold() + Text(SLocale(.FOLLOWING_ACTION))

								})
                            }
                        } else {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Text("\(controller.user.following) ").bold() + Text(SLocale(.FOLLOWING_ACTION))
                            }
                        }
                    }.padding(.trailing)
                        .foregroundColor(Color(UIColor.label))
                }

                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("\(controller.user.postsCount) ").bold() + Text(countString(number: controller.user.postsCount, singleText: SLocale(.POST_NOUN), multiText: SLocale(.POST_NOUN_PLURAL), includeNumber: false))
                }
                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("\(controller.user.repliesCount) ").bold() + Text(countString(number: controller.user.repliesCount, singleText: SLocale(.REPLY_SINGULAR), multiText: SLocale(.REPLY_PLURAL), includeNumber: false))
                }

                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("\(SLocale(.JOINED_AT))\(String(SLocale(.JOINED_AT)).last == " " ? String("") : String(" "))") + Text(dateFormatter.string(from: controller.user.joined)).bold()
                }

				XPProgressBarView(xp: $controller.user.xp).frame(height: 60).padding(.top)

                if !controller.user.labels.isEmpty {
                    HStack {
                        ForEach(controller.user.labels) { label in
                            HStack {
                                Circle().fill(Color(hexStringToUIColor(hex: label.color)))
                                    .frame(width: 20, height: 20)
                                Text(label.name)
                            }.padding(4).padding([.leading, .trailing], 4).overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(UIColor.secondaryLabel), lineWidth: 1))
                        }
                    }.padding(.top)
                }

                if !controller.isLoggedInUser {
                    Button(action: {
                        controller.followUnfollowUser()
                    }, label: {
                        if controller.user.isFollowing {
                            Group {
                                Text(SLocale(.FOLLOWING_ACTION)).padding().foregroundColor(.white)
                            }.background(Color.blue).shadow(radius: 10).cornerRadius(12.0)
                                .padding(.top, 16)
                        } else {
                            Group {
                                Text(SLocale(.FOLLOW_ACTION)).padding().foregroundColor(.blue)
                            }.background(Color("UserBackground")).shadow(radius: 10).cornerRadius(12.0)
                                .padding(.top, 16)
                        }
					})
                }
            }
            .padding(.leading)

        }.padding(16)
            .onAppear {
                controller.getLoggedInUser()
            }
            .background(Color.clear)
		
    }
}

struct FullScreenImageView: UIViewRepresentable {
	var image: UIImage

	func makeUIView(context: Context) -> UIView {
		return UIView()
	}

	func updateUIView(_ uiView: UIView, context: Context) {
		let images = [
			LightboxImage(
				image: image,
				text: ""
			),
		]

		LightboxConfig.CloseButton.text = SLocale(.CLOSE_ACTION)
		let controller = LightboxController(images: images)

		controller.dynamicBackground = true

		uiView.addSubview(controller.view)
	}
}

struct LoadingSkeleton<Content: View>: View {
    @Binding var loaded: Bool
    let viewBuilder: () -> Content
    var body: some View {
        Group {
            viewBuilder()
        }.fixedSize(horizontal: true, vertical: true)
            .skeleton(with: !loaded)
            .shape(type: .capsule)
            .appearance(type: .solid(color: Color.red, background: Color("LoadingSkeleton")))
            .animation(type: .pulse())
            .multiline(lines: 1, scales: [0: 0.5])
    }
}

struct UserHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        UserHeaderView(controller: UserHeaderViewController())
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import KingfisherSwiftUI
import Lightbox
import SkeletonUI
import SwiftUI

struct UserHeaderView: View {
    @ObservedObject var controller: UserHeaderViewController
	@State var profilePicture: UIImage?

    var frameWidth: CGFloat = 0
    var frameHeight: CGFloat = 0

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
					getSwiftUIProfilePicture(controller.user.ring, url: controller.user.profilePictureUrl, binding: $profilePicture, size: 120)
				}.onTapGesture {
					controller.clickProfilePicture(profilePicture)
				}
                Spacer()
            }
            Group {
                HStack {
                    Text("\(controller.user.nickname)\(controller.user.plus ? String("⁺") : String(""))").font(.title).bold()
                }
				Group {
					HStack {
						Text("\(controller.user.name)#\(controller.user.tag)").foregroundColor(.secondary)
						if controller.user.userSubscribedTo {
							Image(systemName: "bell").frame(width: 15, height: 15).foregroundColor(.secondary)
						}
					}
					if controller.user.username != nil {
						Text("@\(controller.user.username!)").foregroundColor(.secondary)
					}
				}
				
                if controller.user.isFollowingMe && !controller.isLoggedInUser {
                    Text("Follows you").foregroundColor(.init(UIColor.tertiaryLabel))
                }

                HStack {
                    Group {
                        if controller.isLoggedInUser {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Button(action: {
                                    controller.showFollowers()
                                }, label: {
                                    Text("\(controller.user.followercount) ").bold() + Text(countString(number: controller.user.followercount, singleText: "Follower", multiText: "Followers", includeNumber: false))

								})
                            }
                        } else {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Text("\(controller.user.followercount) ").bold() + Text(countString(number: controller.user.followercount, singleText: "Follower", multiText: "Followers", includeNumber: false))
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
                                    Text("\(controller.user.followingcount) ").bold() + Text("Following")

								})
                            }
                        } else {
                            LoadingSkeleton(loaded: $controller.userDataLoaded) {
                                Text("\(controller.user.followingcount) ").bold() + Text("Following")
                            }
                        }
                    }.padding(.trailing)
                        .foregroundColor(Color(UIColor.label))
                }

                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("\(controller.user.postsCount) ").bold() + Text(countString(number: controller.user.postsCount, singleText: "Post", multiText: "Posts", includeNumber: false))
                }
                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("\(controller.user.repliesCount) ").bold() + Text(countString(number: controller.user.repliesCount, singleText: "Reply", multiText: "Replies", includeNumber: false))
                }

                LoadingSkeleton(loaded: $controller.userDataLoaded) {
                    Text("Joined: ") + Text(dateFormatter.string(from: controller.user.createdAt)).bold()
                }

                if controller.user.status.content != nil, controller.user.status.date != nil {
                    Text("\"\(controller.user.status.content!)\"").italic()
                        .fixedSize(horizontal: false, vertical: true).frame(maxWidth: frameWidth - 40, alignment: .leading).lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)

                    LoadingSkeleton(loaded: $controller.userDataLoaded) {
                        Text("\(RelativeDateTimeFormatter().localizedString(for: controller.user.status.date!, relativeTo: Date()))").font(.footnote).foregroundColor(.secondary).padding(.bottom, 4)
                    }
                }

                XPProgressBarView(xp: $controller.user.xp).frame(height: 60).padding(.top)

                if !controller.isLoggedInUser {
                    Button(action: {
                        controller.followUnfollowUser()
                    }, label: {
                        if controller.user.iamFollowing {
                            Group {
                                Text("Following").padding().foregroundColor(.white)
                            }.background(Color.blue).shadow(radius: 10).cornerRadius(12.0)
                                .padding(.top, 16)
                        } else {
                            Group {
                                Text("Follow").padding().foregroundColor(.blue)
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

struct EmbeddedProfilePictureView: View {
	var ring: ProfileRing
	var url: URL
	var size: Int
	@State var image: UIImage?
	var addShadow: Bool
	var body: some View {
		getSwiftUIProfilePicture(ring, url: url, binding: $image, size: size, addShadow: addShadow)
	}
}

func getSwiftUIProfilePicture(_ ring: ProfileRing, url: URL, binding: Binding<UIImage?>, size: Int, addShadow: Bool = true) -> some View {
	switch ring {
	case .rainbow:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(RainbowFlagCircle(addShadow: addShadow)))
	case .trans:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(TransFlagCircle(addShadow: addShadow)))
	case .bisexual:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(BisexualFlagCircle(addShadow: addShadow)))
	case .pansexual:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(PansexualFlagCircle(addShadow: addShadow)))
	case .lesbian:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(LesbianFlagCircle(addShadow: addShadow)))
	case .asexual:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(AsexualFlagCircle(addShadow: addShadow)))
	case .genderqueer:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(GenderqueerFlagCircle(addShadow: addShadow)))
	case .genderfluid:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(GenderfluidFlagCircle(addShadow: addShadow)))
	case .agender:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(AgenderFlagCircle(addShadow: addShadow)))
	case .nonbinary:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(NonbinaryFlagCircle(addShadow: addShadow)))
	case .supporter:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow).modifier(SpicaSupporterFlagCircle(addShadow: addShadow)))
	default:
		return AnyView(ProfilePictureView(url: url, size: size, profilePicture: binding, addShadow: addShadow))
	}
}

struct ProfilePictureView: View {
    var url: URL
	var size: Int = 120
	@Binding var profilePicture: UIImage?
	var addShadow: Bool = true
    var body: some View {
		KFImage(url)
			.onSuccess { r in
				profilePicture = r.image
			}
			.resizable()
			.frame(width: CGFloat(size), height: CGFloat(size), alignment: .center)
			.clipShape(Circle())
			.shadow(radius: addShadow ? 10 : 0)
			
    }
}

struct FullScreenImageView: UIViewRepresentable {
    var image: UIImage

    func makeUIView(context _: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context _: Context) {
        let images = [
            LightboxImage(
                image: image,
                text: ""
            ),
        ]

        LightboxConfig.CloseButton.text = "Close"
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
		UserHeaderView(controller: UserHeaderViewController(user: User.sample, userDataLoaded: true))
    }
}

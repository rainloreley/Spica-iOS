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
                    // Image(uiImage: controller.user.image ?? UIImage(systemName: "person.circle"))
                    switch controller.user.ring {
                    case .rainbow:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(RainbowFlagCircle())
                    case .trans:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(TransFlagCircle())
                    case .bisexual:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(BisexualFlagCircle())
                    case .pansexual:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(PansexualFlagCircle())
                    case .lesbian:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(LesbianFlagCircle())
                    case .asexual:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(AsexualFlagCircle())
                    case .genderqueer:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(GenderqueerFlagCircle())
                    case .genderfluid:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(GenderfluidFlagCircle())
                    case .agender:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(AgenderFlagCircle())
                    case .nonbinary:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(NonbinaryFlagCircle())
                    case .supporter:
                        ProfilePictureView(url: controller.user.profilePictureUrl).modifier(SpicaSupporterFlagCircle())
                    default:
                        ProfilePictureView(url: controller.user.profilePictureUrl)
                    }
                }
                Spacer()
            }
            Group {
                HStack {
                    Text("\(controller.user.nickname)\(controller.user.plus ? String("⁺") : String(""))").font(.title).bold()
                }
                Text("\(controller.user.name)#\(controller.user.tag)").foregroundColor(.secondary)
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
                    LoadingSkeleton(loaded: $controller.userDataLoaded) {
                        Text("\"\(controller.user.status.content!)\"").italic().frame(maxWidth: frameWidth - 40).lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.leading)
                            .padding(.top, 4)
                    }
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
        // .frame(width: frameWidth, height: frameHeight)
    }
}

struct ProfilePictureView: View {
    var url: URL
    var body: some View {
        KFImage(url)
            .resizable()
            .frame(width: 120, height: 120, alignment: .center)
            .clipShape(Circle())
            .shadow(radius: 10)
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
        UserHeaderView(controller: UserHeaderViewController())
    }
}

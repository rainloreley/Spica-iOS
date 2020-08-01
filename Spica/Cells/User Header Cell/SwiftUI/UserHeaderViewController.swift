//
//  UserHeaderViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import Combine
import SwiftKeychainWrapper
import SwiftUI

protocol UserHeaderDelegate {
    func followUnfollowUser(uid: String)
}

class UserHeaderViewController: ObservableObject {
    @Published var user: User = User(id: "0000", username: "user", displayName: "user", nickname: "user", imageURL: URL(string: "https://avatar.alles.cx/u/000000000000000000000000")!, isPlus: false, rubies: 0, followers: 0, image: UIImage(systemName: "person.circle")!, isFollowing: false, followsMe: false, about: "", isOnline: false)

    @Published var grow: Bool = false

    @Published var isLoggedInUser: Bool = false

    var delegate: UserHeaderDelegate!

    func followUnfollowUser() {
        user.isFollowing.toggle()
        delegate.followUnfollowUser(uid: user.id)
    }

    func getLoggedInUser() {
        let signedInUsername = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")

        isLoggedInUser = user.username == signedInUsername
    }
}

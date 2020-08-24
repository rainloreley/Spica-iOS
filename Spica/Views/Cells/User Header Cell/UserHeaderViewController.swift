//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftKeychainWrapper
import SwiftUI

protocol UserHeaderDelegate {
    func followUnfollowUser(uid: String)
    func clickedOnFollowerCount()
    func clickedOnFollowingCount()
}

class UserHeaderViewController: ObservableObject {
    @Published var user: User = User()

    @Published var userDataLoaded: Bool = false

    @Published var grow: Bool = false

    @Published var isLoggedInUser: Bool = false

    var delegate: UserHeaderDelegate!

    func followUnfollowUser() {
        user.isFollowing.toggle()
        delegate.followUnfollowUser(uid: user.id)
    }

    func showFollowers() {
        delegate.clickedOnFollowerCount()
    }

    func showFollowing() {
        delegate.clickedOnFollowingCount()
    }

    func getLoggedInUser() {
        let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

        isLoggedInUser = user.id == signedInID
    }
}

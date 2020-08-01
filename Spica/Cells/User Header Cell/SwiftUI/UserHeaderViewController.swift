//
//  UserHeaderViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import SwiftUI
import Combine
import SwiftKeychainWrapper

protocol UserHeaderDelegate {
	func followUnfollowUser(uid: String)
}

class UserHeaderViewController: ObservableObject {
	@Published var user: User = User(id: "0000", username: "adriann", displayName: "Adrian", nickname: "Adrian", imageURL: URL(string: "https://avatar.alles.cx/u/adrian")!, isPlus: true, rubies: 100, followers: 293, image: UIImage(systemName: "person.circle")!, isFollowing: false, followsMe: true, about: "Hello!", isOnline: true)
	
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

//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 13.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

extension MicroAPI {
	func getErrorMessage(error: String) -> String {
		switch error {
			case "alreadySet":
				return "This value has already been set and cannot be updated."
			case "badAuthorization":
				return "You're unauthorized to access this resource."
			case "badRequest":
				return "Not all required parameters were sent."
			case "billing.invalidPlan":
				return "This subscription plan cannot be subscribed to as it is not valid."
			case "billing.unregistered":
				return "This account does not have billing set up."
			case "email.invalid":
				return "This email address cannot be used because it is invalid."
			case "internalError":
				return "Something went wrong with the server. Contact support if this continues."
			case "micro.post.invalidUrl":
				return "The url is not valid so it cannot be posted."
			case "micro.post.length":
				return "The post content does not meet the length requirements."
			case "micro.post.notAuthor":
				return "This action cannot be performed on this post because the user is not the author of it."
			case "micro.post.parent":
				return "This reply cannot be posted because the parent does not exist."
			case "missingResource":
				return "The data that was requested does not exist."
			case "notFound":
				return "This endpoint does not exist."
			case "plusOnly":
				return "You must have Alles+ in order to make this request."
			case "profile.name.tooLong":
				return "This name cannot be set because it is too long."
			case "profile.name.tooMany":
				return "This name is used by too many other users."
			case "profile.name.tooShort":
				return "This name cannot be set because it is too short."
			case "profile.nickname.tooLong":
				return "This nickname cannot be set because it is too long."
			case "profile.nickname.tooShort":
				return "This nickname cannot be set because it is too short."
			case "profile.tag.invalid":
				return "This tag cannot be set because it is invalid. Tags must be 4-digit integers between 0001 and 9999."
			case "profile.tag.unavailable":
				return "This tag cannot be set because another user with the same name is using the tag."
			case "profile.username.invalid":
				return "This username cannot be set because it does not match the requirements."
			case "profile.username.tooLong":
				return "This username cannot be set because it is too long."
			case "profile.username.tooShort":
				return "This username cannot be set because it is too short."
			case "profile.username.unavailable":
				return "This username cannot be set because it is already in use by another user."
			case "pulsar.unsupportedVersion":
				return "The Pulsar client is not permitted to access the API, since it is an unsupported version."
			case "quickauth.badToken":
				return "The QuickAuth token is invalid."
			case "quickauth.unregisteredRedirect":
				return "The redirect url cannot be used for security reasons because it is not registered to the application."
			case "session.badToken":
				return "The session token provided is invalid."
			case "user.follow.self":
				return "You can't follow yourself"
			case "user.password.incorrect":
				return "This password is incorrect"
			case "user.password.length":
				return "This password does not meet the length requirements."
			case "user.password.same":
				return "This password cannot be set because it is the same as the current password."
			case "user.signIn.credentials":
				return "These credentials are incorrect and cannot be used to sign in."
			case "user.xp.notEnough":
				return "You don't have enough xp to perform this action."
			default: return "There's no custom error message for \"\(error)\". Please contact Spica Support."
		}
	}
}

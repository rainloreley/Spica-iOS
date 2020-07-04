//
//  AllesAPIErrorHandler.swift
//  Spica
//
//  Created by Adrian Baumgart on 02.07.20.
//

import Foundation

public class AllesAPIErrorHandler {
    static let `default` = AllesAPIErrorHandler()

    public func returnError(error: String) -> AllesAPIErrorMessage {
        switch error {
        case "alreadySet":
            return .init(message: "This action has been performed before", error: .alreadySet, actionParameter: nil, action: nil)
        case "applications.badRedirect":
            return .init(message: "The redirect URL is not allowed or malformed", error: .applications_badRedirect, actionParameter: nil, action: nil)
        case "applications.firstPartyOnly":
            return .init(message: "This action can only be performed by first party services", error: .applications_firstPartyOnly, actionParameter: nil, action: nil)
        case "applications.scopes.invalid":
            return .init(message: "A requested OAuth scope does not exist", error: .applications_scopes_invalid, actionParameter: nil, action: nil)
        case "applications.scopes.tooMany":
            return .init(message: "Too many OAuth scopes were specified", error: .applications_scopes_tooMany, actionParameter: nil, action: nil)
        case "badAuthorization":
            return .init(message: "You're not authorized to perform this action. We'll redirect you to the login screen", error: .badAuth, actionParameter: "login", action: .navigate)
        case "badRequest":
            return .init(message: "Some data is missing", error: .badRequest, actionParameter: nil, action: nil)
        case "billing.invalidPlan":
            return .init(message: "This plan does not exist", error: .billing_invalidPlan, actionParameter: nil, action: nil)
        case "billing.unregistered":
            return .init(message: "You need to setup billing first", error: .billing_unregistered, actionParameter: nil, action: nil)
        case "bot":
            return .init(message: "We can't verify that you're a human (if you're a bot: it's ok to be a bot, don't be sad)", error: .bot, actionParameter: nil, action: nil)
        case "email.inUse":
            return .init(message: "This email address is already in use", error: .email_inUse, actionParameter: nil, action: nil)
        case "email.invalid":
            return .init(message: "Your email address is invalid", error: .email_invalid, actionParameter: nil, action: nil)
        case "internalError":
            return .init(message: "An internal error occurred (archie, are you messsing with the database again?)", error: .internalError, actionParameter: nil, action: nil)
        case "missingResource":
            return .init(message: "The resource you requested does not exist", error: .missingResource, actionParameter: nil, action: nil)
        case "notFound":
            return .init(message: "This endpoint does not exist", error: .notFound, actionParameter: nil, action: nil)
        case "plusOnly":
            return .init(message: "This action can only be performed by Alles+ members (just buy alles+ :D)", error: .plusOnly, actionParameter: nil, action: nil)
        case "post.content.length":
            return .init(message: "The content length is invalid (too short or too long)", error: .post_content_length, actionParameter: nil, action: nil)
        case "post.invalidParent":
            return .init(message: "The parent post is invalid", error: .post_invalidParent, actionParameter: nil, action: nil)
        case "primaryOnly":
            return .init(message: "This action is only available for primary accounts", error: .primaryOnly, actionParameter: nil, action: nil)
        case "profile.username.chars":
            return .init(message: "A character in your username is invalid", error: .profile_username_chars, actionParameter: nil, action: nil)
        case "profile.username.unavailable":
            return .init(message: "This username is not available!", error: .profile_username_unavailable, actionParameter: nil, action: nil)
        case "profile.username.tooShort":
            return .init(message: "Your username is too short", error: .profile_name_tooShort, actionParameter: nil, action: nil)
        case "profile.username.tooLong":
            return .init(message: "Your username is too long", error: .profile_username_tooLong, actionParameter: nil, action: nil)
        case "profile.name.tooShort":
            return .init(message: "Your name is too short", error: .profile_name_tooShort, actionParameter: nil, action: nil)
        case "profile.name.tooLong":
            return .init(message: "Your name is too long", error: .profile_name_tooLong, actionParameter: nil, action: nil)
        case "profile.nickname.tooShort":
            return .init(message: "Your nickname is too short", error: .profile_nickname_tooShort, actionParameter: nil, action: nil)
        case "profile.nickname.tooLong":
            return .init(message: "Your nickname is too long", error: .profile_nickname_tooLong, actionParameter: nil, action: nil)
        case "profile.about.tooShort":
            return .init(message: "Your about text is too short", error: .profile_about_tooShort, actionParameter: nil, action: nil)
        case "profile.about.tooLong":
            return .init(message: "Your about text is too long", error: .profile_about_tooLong, actionParameter: nil, action: nil)
        case "pulsar.badToken":
            return .init(message: "The pulsar token is invalid", error: .pulsar_badToken, actionParameter: nil, action: nil)
        case "rateLimited":
            return .init(message: "This action has been performed too much in a certain period of time", error: .rateLimited, actionParameter: nil, action: nil)
        case "restrictedAccess":
            return .init(message: "This AllesID is not permitted to perform the request", error: .restrictedAccess, actionParameter: nil, action: nil)
        case "stableOnly":
            return .init(message: "You cannot perform this action on the beta version", error: .stableOnly, actionParameter: nil, action: nil)
        case "user.follow.limit":
            return .init(message: "The amount of people you can follow is limited", error: .user_follow_limit, actionParameter: nil, action: nil)
        case "user.follow.self":
            return .init(message: "You cannot follow yourself (nice try)", error: .user_follow_self, actionParameter: nil, action: nil)
        case "user.password.incorrect":
            return .init(message: "The password is incorrect", error: .user_password_incorrect, actionParameter: nil, action: nil)
        case "user.password.requirements":
            return .init(message: "The password does not meet the requirements. Try making it more complex", error: .user_password_requirements, actionParameter: nil, action: nil)
        case "user.password.same":
            return .init(message: "The old and new passwords match", error: .user_password_same, actionParameter: nil, action: nil)
        case "user.signIn.credentials":
            return .init(message: "This username / password is invalid", error: .user_signIn_credentials, actionParameter: nil, action: nil)
        case "validation.chars":
            return .init(message: "The input contains characters that are not allowed (please don't break Alles)", error: .validation_chars, actionParameter: nil, action: nil)
        case "validation.tooShort":
            return .init(message: "The input is too short", error: .validation_tooShort, actionParameter: nil, action: nil)
        case "validation.tooLong":
            return .init(message: "The input is too long", error: .validation_tooLong, actionParameter: nil, action: nil)
        default:
            return .init(message: "An unknown error occurred (you did it)", error: .unknown, actionParameter: nil, action: nil)
        }
    }
}

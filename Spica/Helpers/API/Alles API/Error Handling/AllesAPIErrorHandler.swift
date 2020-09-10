//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 02.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

/// Alles API Error Handler
public class AllesAPIErrorHandler {
    static let `default` = AllesAPIErrorHandler()

    /// Handles errors (and gives instructions)
    /// - Parameter error: API error string
    /// - Returns: `AllesAPIErrorMessage`
    public func returnError(error: String) -> AllesAPIErrorMessage {
        switch error {
        case "alreadySet":
            return .init(message: SLocale(.error_alreadySet), error: .alreadySet, actionParameter: nil, action: nil)
        case "applications.badRedirect":
            return .init(message: SLocale(.error_applications_badRedirect), error: .applications_badRedirect, actionParameter: nil, action: nil)
        case "applications.firstPartyOnly":
            return .init(message: SLocale(.error_applications_firstPartyOnly), error: .applications_firstPartyOnly, actionParameter: nil, action: nil)
        case "applications.scopes.invalid":
            return .init(message: SLocale(.error_applications_scopes_invalid), error: .applications_scopes_invalid, actionParameter: nil, action: nil)
        case "applications.scopes.tooMany":
            return .init(message: SLocale(.error_applications_scopes_tooMany), error: .applications_scopes_tooMany, actionParameter: nil, action: nil)
        case "badAuthorization":
            return .init(message: SLocale(.error_badAuthorization), error: .badAuth, actionParameter: "login", action: .navigate)
        case "badRequest":
            return .init(message: SLocale(.error_badRequest), error: .badRequest, actionParameter: nil, action: nil)
        case "billing.invalidPlan":
            return .init(message: SLocale(.error_billing_invalidPlan), error: .billing_invalidPlan, actionParameter: nil, action: nil)
        case "billing.unregistered":
            return .init(message: SLocale(.error_billing_unregistered), error: .billing_unregistered, actionParameter: nil, action: nil)
        case "bot":
            return .init(message: SLocale(.error_bot), error: .bot, actionParameter: nil, action: nil)
        case "email.inUse":
            return .init(message: SLocale(.error_email_inUse), error: .email_inUse, actionParameter: nil, action: nil)
        case "email.invalid":
            return .init(message: SLocale(.error_email_invalid), error: .email_invalid, actionParameter: nil, action: nil)
        case "internalError":
            return .init(message: SLocale(.error_internalError), error: .internalError, actionParameter: nil, action: nil)
        case "missingResource":
            return .init(message: SLocale(.error_missingResource), error: .missingResource, actionParameter: nil, action: nil)
        case "notFound":
            return .init(message: SLocale(.error_notFound), error: .notFound, actionParameter: nil, action: nil)
        case "plusOnly":
            return .init(message: SLocale(.error_plusOnly), error: .plusOnly, actionParameter: nil, action: nil)
        case "post.content.length":
            return .init(message: SLocale(.error_post_content_length), error: .post_content_length, actionParameter: nil, action: nil)
        case "post.invalidParent":
            return .init(message: SLocale(.error_post_invalidParent), error: .post_invalidParent, actionParameter: nil, action: nil)
        case "primaryOnly":
            return .init(message: SLocale(.error_primaryOnly), error: .primaryOnly, actionParameter: nil, action: nil)
        case "profile.username.chars":
            return .init(message: SLocale(.error_profile_username_chars), error: .profile_username_chars, actionParameter: nil, action: nil)
        case "profile.username.unavailable":
            return .init(message: SLocale(.error_profile_username_unavailable), error: .profile_username_unavailable, actionParameter: nil, action: nil)
        case "profile.username.tooShort":
            return .init(message: SLocale(.error_profile_username_tooShort), error: .profile_name_tooShort, actionParameter: nil, action: nil)
        case "profile.username.tooLong":
            return .init(message: SLocale(.error_profile_username_tooLong), error: .profile_username_tooLong, actionParameter: nil, action: nil)
        case "profile.name.tooShort":
            return .init(message: SLocale(.error_profile_name_tooShort), error: .profile_name_tooShort, actionParameter: nil, action: nil)
        case "profile.name.tooLong":
            return .init(message: SLocale(.error_profile_name_tooLong), error: .profile_name_tooLong, actionParameter: nil, action: nil)
        case "profile.nickname.tooShort":
            return .init(message: SLocale(.error_profile_nickname_tooShort), error: .profile_nickname_tooShort, actionParameter: nil, action: nil)
        case "profile.nickname.tooLong":
            return .init(message: SLocale(.error_profile_nickname_tooLong), error: .profile_nickname_tooLong, actionParameter: nil, action: nil)
        case "profile.about.tooShort":
            return .init(message: SLocale(.error_profile_about_tooShort), error: .profile_about_tooShort, actionParameter: nil, action: nil)
        case "profile.about.tooLong":
            return .init(message: SLocale(.error_profile_about_tooLong), error: .profile_about_tooLong, actionParameter: nil, action: nil)
        case "pulsar.badToken":
            return .init(message: SLocale(.error_pulsar_badToken), error: .pulsar_badToken, actionParameter: nil, action: nil)
        case "rateLimited":
            return .init(message: SLocale(.error_rateLimited), error: .rateLimited, actionParameter: nil, action: nil)
        case "restrictedAccess":
            return .init(message: SLocale(.error_restrictedAccess), error: .restrictedAccess, actionParameter: nil, action: nil)
        case "stableOnly":
            return .init(message: SLocale(.error_stableOnly), error: .stableOnly, actionParameter: nil, action: nil)
        case "user.follow.limit":
            return .init(message: SLocale(.error_user_follow_limit), error: .user_follow_limit, actionParameter: nil, action: nil)
        case "user.follow.self":
            return .init(message: SLocale(.error_user_follow_self), error: .user_follow_self, actionParameter: nil, action: nil)
        case "user.password.incorrect":
            return .init(message: SLocale(.error_user_password_incorrect), error: .user_password_incorrect, actionParameter: nil, action: nil)
        case "user.password.requirements":
            return .init(message: SLocale(.error_user_password_requirements), error: .user_password_requirements, actionParameter: nil, action: nil)
        case "user.password.same":
            return .init(message: SLocale(.error_user_password_same), error: .user_password_same, actionParameter: nil, action: nil)
        case "user.signIn.credentials":
            return .init(message: SLocale(.error_user_signIn_credentials), error: .user_signIn_credentials, actionParameter: nil, action: nil)
        case "validation.chars":
            return .init(message: SLocale(.error_validation_chars), error: .validation_chars, actionParameter: nil, action: nil)
        case "validation.tooShort":
            return .init(message: SLocale(.error_validation_tooShort), error: .validation_tooShort, actionParameter: nil, action: nil)
        case "validation.tooLong":
            return .init(message: SLocale(.error_validation_tooLong), error: .validation_tooLong, actionParameter: nil, action: nil)

        case "spica_authTokenMissing":
            return .init(message: SLocale(.error_spica_authTokenMissing), error: .spica_authTokenMissing, actionParameter: "login", action: .navigate)

        case "spica_noLoginTokenReturned":
            return .init(message: SLocale(.error_spica_noLoginTokenReturned), error: .spica_noLoginTokenReturned, actionParameter: nil, action: nil)

        case "spica_invalidStatusCode":
            return .init(message: SLocale(.error_spica_invalidStatusCode), error: .spica_invalidStatusCode, actionParameter: nil, action: nil)

        case "spica_unknownError":
            return .init(message: SLocale(.error_spica_unknownError), error: .spica_unknownError, actionParameter: nil, action: nil)

        case "spica_valueNotAllowed":
            return .init(message: SLocale(.error_spica_valueNotAllowed), error: .spica_valueNotAllowed, actionParameter: nil, action: nil)

        default:
            return .init(message: SLocale(.error_default), error: .unknown, actionParameter: nil, action: nil)
        }
    }
}

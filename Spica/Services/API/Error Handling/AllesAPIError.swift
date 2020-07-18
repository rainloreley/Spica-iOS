//
//  AllesAPIError.swift
//  Spica
//
//  Created by Adrian Baumgart on 02.07.20.
//

import Foundation

public enum AllesAPIError: Error {
    case alreadySet
    case applications_badRedirect
    case applications_firstPartyOnly
    case applications_scopes_invalid
    case applications_scopes_tooMany
    case badAuth
    case badRequest
    case billing_invalidPlan
    case billing_unregistered
    case bot
    case email_inUse
    case email_invalid
    case internalError
    case missingResource
    case notFound
    case plusOnly
    case post_content_length
    case post_invalidParent
    case primaryOnly
    case profile_username_chars
    case profile_username_unavailable
    case profile_username_tooShort
    case profile_username_tooLong
    case profile_name_tooShort
    case profile_name_tooLong
    case profile_nickname_tooShort
    case profile_nickname_tooLong
    case profile_about_tooShort
    case profile_about_tooLong
    case pulsar_badToken
    case rateLimited
    case restrictedAccess
    case stableOnly
    case user_follow_limit
    case user_follow_self
    case user_password_incorrect
    case user_password_requirements
    case user_password_same
    case user_signIn_credentials
    case validation_chars
    case validation_tooShort
    case validation_tooLong

    case spica_authTokenMissing
    case spica_noLoginTokenReturned
    case spica_invalidStatusCode
    case spica_unknownError
    case spica_valueNotAllowed

    case unknown
}

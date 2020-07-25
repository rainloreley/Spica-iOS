//
//  FollowAction.swift
//  Spica
//
//  Created by Adrian Baumgart on 22.07.20.
//

import Foundation

public enum FollowAction {
    case follow, unfollow

    var actionString: String {
        switch self {
        case .follow: return "follow"
        case .unfollow: return "unfollow"
        }
    }
}

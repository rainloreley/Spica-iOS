//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Foundation
import SwiftUI

class LoginController: ObservableObject {
    var delegate: LoginViewDelegate?

    @Published var nametag: String = ""
    @Published var password: String = ""

    @Published var nametagError: Bool = false
    @Published var passwordError: Bool = false

    @Published var showAlert = false
    @Published var alertMessage = ""

    func login() {
        nametagError = false
        passwordError = false

        if !nametag.isEmpty, !password.isEmpty {
            let splitUsername = nametag.split(separator: "#")
            if splitUsername.count != 2 || Int(splitUsername[1]) == nil || splitUsername[1].count != 4 {
                nametagError = true
            } else {
                MicroAPI.default.signIn(name: String(splitUsername[0]), tag: String(splitUsername[1]), password: password) { result in
                    switch result {
                    case let .failure(err):
                        DispatchQueue.main.async { [self] in
                            alertMessage = "Login failed with the following error:\n\n\(err.error.humanDescription)"
                            showAlert = true
                        }
                    case let .success(token):
                        DispatchQueue.main.async { [self] in
                            delegate!.loggedIn(token: token)
                        }
                    }
                }
            }
        } else {
            if nametag.isEmpty {
                nametagError = true
            }
            if password.isEmpty {
                passwordError = true
            }
        }
    }
}

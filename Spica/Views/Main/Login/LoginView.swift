//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 21.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        NavigationView {
            VStack {
                SignInWithAllesButton {
                    UIApplication.shared.open(URL(string: "https://www.youtube.com/watch?v=oHg5SJYRHA0")!)
                }.padding()

                Button(action: {
                    UIApplication.shared.open(URL(string: "https://spica.li/privacy")!)
                }, label: {
                    Text("Spica: \(SLocale(.PRIVACY_POLICY))")
				}).padding()
                Button(action: {}, label: {
                    Text("Alles: \(SLocale(.TERMS_OF_SERVICE))")
				}).padding()
                Button(action: {}, label: {
                    Text("Alles: \(SLocale(.PRIVACY_POLICY))")
				}).padding()

                Text(SLocale(.LOGIN_SCREEN_AGREEMENT)).padding().foregroundColor(Color(UIColor.secondaryLabel)).font(.footnote)

            }.navigationBarTitle(SLocale(.ALLES_LOGIN))

        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

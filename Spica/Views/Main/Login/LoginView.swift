//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

protocol LoginViewDelegate {
    func loggedIn(token: String)
}

struct LoginView: View {
    @ObservedObject var controller: LoginController

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    Text("Nametag:")
                    Spacer()
                }
                TextField("Lea#0001", text: $controller.nametag).border(controller.nametagError ? Color.red : Color.clear).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.bottom, 16)
                HStack {
                    Text("Password:")
                    Spacer()
                }
                SecureField("•••••", text: $controller.password).border(controller.passwordError ? Color.red : Color.clear).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.bottom, 16)

                Button(action: {
                    controller.login()
                }, label: {
                    Text("Login").bold().foregroundColor(.white).padding([.leading, .trailing])
				}).padding().background(Color.blue).cornerRadius(12)
                Spacer()
               /**/

            }.padding().navigationBarTitle(Text("Login"))
                .alert(isPresented: $controller.showAlert) {
                    Alert(title: Text("Error"), message: Text("\(controller.alertMessage)"), dismissButton: .default(Text("Ok")))
				}.background(
					VStack {
						Spacer()
						Text("By signing in, you agree to")
						HStack {
							Button(action: {
								let url = URL(string: "https://files.alles.cc/Documents/Terms%20of%20Service.txt")!
								if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
							}, label: {
								Text("Alles Terms of Service,")
							})
							Button(action: {
								let url = URL(string: "https://files.alles.cc/Documents/Privacy%20Policy.txt")!
								if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
							}, label: {
								Text("Privacy Policy")
							})
						}.foregroundColor(.blue)
							.padding(1)
						Text("and")
						HStack {
							Button(action: {
								let url = URL(string: "https://spica.li/privacy")!
								if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
							}, label: {
								Text("Spicas Privacy Policy")
							})
						}.foregroundColor(.blue)
							.padding(1)
					}.padding(.bottom, 32).multilineTextAlignment(.center).font(.footnote).foregroundColor(.secondary)
					.edgesIgnoringSafeArea(.bottom)
				)
        }.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(controller: LoginController())
    }
}

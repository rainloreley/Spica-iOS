//
//  SignInWithAllesButton.swift
//  Spica
//
//  Created by Adrian Baumgart on 21.08.20.
//

import SwiftUI

struct SignInWithAllesButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Group {
                HStack {
                    Image("Alles Rainbow").resizable().frame(width: 40, height: 40, alignment: .leading).padding([.top, .bottom])
                    Text("Continue with Alles").bold().foregroundColor(.init(UIColor.label))
                }
            }.frame(maxWidth: .infinity).background(Color(UIColor.secondarySystemBackground)) /* .background(Color("Sign in with Alles")) */ .cornerRadius(20)

		})
    }
}

struct SignInWithAllesButton_Previews: PreviewProvider {
    static var previews: some View {
        SignInWithAllesButton {
            //
        }.padding()
        /* SignInWithAllesButton()
         .previewLayout(.fixed(width: 300, height: 70)) */
    }
}

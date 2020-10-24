//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 23.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct UpdateStatusView: View {
    @ObservedObject var controller: UpdateStatusController
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Status:").bold()
                TextField("", text: $controller.enteredText).textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Expiration date:").bold()
                DatePicker("", selection: $controller.selectedDate, in: Date() ... Date().addingTimeInterval(604_800))
            }
            Button(action: {
                controller.updateStatus()
			}) {
                Text("Update").foregroundColor(.white)
            }.frame(maxWidth: .infinity).padding().background(Color.accentColor).cornerRadius(12)
                .padding([.top, .bottom], 2)

            Button(action: {
                controller.clearStatus()
			}) {
                Text("Clear").foregroundColor(.white)
            }.frame(maxWidth: .infinity).padding().background(Color.accentColor).cornerRadius(12)
                .padding([.top, .bottom], 2)
        }
    }
}

struct UpdateStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateStatusView(controller: .init())
    }
}

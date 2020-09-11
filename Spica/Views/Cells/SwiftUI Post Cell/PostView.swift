//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 19.08.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct PostView: View {
    var body: some View {
        Group {
            HStack {
                VStack {
                    Text("+")
                    Text("20")
                    Text("-")
                }
                .padding()
                Divider()
                VStack(alignment: .leading) {
                    HStack {
                        Image("jsoPfp").resizable().frame(width: 40, height: 40, alignment: .leading).cornerRadius(20)
                        Text("Jason").bold()
                        Spacer()
                    }.padding()
                    Text("This is a cool text")

                    Image("translate").resizable().frame(width: 200, height: 200, alignment: .center)
                    Group {
                        Text("https://google.com").padding(2)
                    }.frame(maxWidth: .infinity)

                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(UIColor.secondaryLabel), lineWidth: 1))
                        .padding([.leading, .trailing])
                    HStack {
                        Text("19.08.2020, 11:57")
                        Spacer()
                        Text("1 Reply")
                    }.padding()
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }.frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView().padding()
    }
}

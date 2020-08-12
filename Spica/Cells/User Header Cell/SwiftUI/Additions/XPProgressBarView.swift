//
//  XPProgressBarView.swift
//  Spica
//
//  Created by Adrian Baumgart on 11.08.20.
//

import SwiftUI

struct XPProgressBarView: View {
    @State var xp: XP = XP(total: 60, level: 1, levelXP: 60, levelXPMax: 1000, levelProgress: 0.06)
    var body: some View {
        GeometryReader(content: { geometry in
            VStack(alignment: .leading) {
                Group {
                    // GeometryReader(content: { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(0.3)
                            .foregroundColor(Color(UIColor.systemGreen))

                        Rectangle().frame(width: min(CGFloat(self.xp.levelProgress) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }.frame(width: geometry.size.width / 2, height: 20, alignment: .leading)
                }
                .cornerRadius(45)
                .shadow(radius: 8)
                // })
                Text("Lvl. \(xp.level); \(Int(xp.levelProgress * 100))% (\(xp.levelXP)/\(xp.levelXPMax))").padding(.leading)
            }

		})
    }
}

struct XPProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        XPProgressBarView()
    }
}

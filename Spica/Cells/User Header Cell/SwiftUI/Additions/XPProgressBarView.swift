//
//  XPProgressBarView.swift
//  Spica
//
//  Created by Adrian Baumgart on 11.08.20.
//

import SwiftUI

struct XPProgressBarView: View {
    @Binding var xp: XP /* = XP(total: 300_120, level: 69, levelXP: 4320, levelXPMax: 7800, levelProgress: 0.5538461538461539) */
    var body: some View {
        GeometryReader(content: { geometry in
            VStack(alignment: .leading) {
                Group {
                    // GeometryReader(content: { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .opacity(0.3)
                            .foregroundColor(Color(UIColor.systemGreen))

                        /* Rectangle().frame(width: min(CGFloat(self.xp.levelProgress) * geometry.size.width < 1000 ? geometry.size.width : geometry.size.width / 2, geometry.size.width < 1000 ? geometry.size.width : geometry.size.width / 2), height: geometry.size.height) */
                        Rectangle().frame(width: CGFloat(self.xp.levelProgress) * (geometry.size.width / 2), height: geometry.size.height, alignment: .leading)
                            .foregroundColor(Color(UIColor.systemGreen))
                    }.frame(width: geometry.size.width / 2, height: 20, alignment: .leading)
                }
                .cornerRadius(45)
                .shadow(radius: 8)
                // })
                Text("\(xp.total)").bold() + Text(" XP")
                Text("Lvl. \(xp.level); \(Int(xp.levelProgress * 100))% (\(xp.levelXP)/\(xp.levelXPMax))")
                /* HStack {

                     Spacer()

                 }.frame(width: (geometry.size.width / 2), height: 20, alignment: .leading) */
            }

		})
    }
}

struct XPProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        XPProgressBarView(xp: .constant(XP(total: 0, level: 0, levelXP: 0, levelXPMax: 0, levelProgress: 0)))
    }
}

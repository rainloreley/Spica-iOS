//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct XPProgressBarView: View {
	@Binding var xp: XP
	var body: some View {
		GeometryReader(content: { geometry in
			HStack {
				VStack(alignment: .leading) {
					Group {
						ZStack(alignment: .leading) {
							Rectangle().frame(width: geometry.size.width / 2, height: geometry.size.height)
								.opacity(0.3)
								.foregroundColor(Color(UIColor.systemGreen))
							Rectangle().frame(width: CGFloat(self.xp.progress) * (geometry.size.width / 2), height: geometry.size.height, alignment: .leading)
								.foregroundColor(Color(UIColor.systemGreen))
						}.frame(width: geometry.size.width / 2, height: 20, alignment: .leading)
					}
					.cornerRadius(45)
					.shadow(radius: 8)
					Text("\(xp.total)").bold() + Text(" XP")
					Text("Lvl. \(xp.level); \(Int(xp.progress * 100))% (\(xp.levelXP)/\(xp.levelXPMax))")
				}

				Spacer()
			}
		})
	}
}

struct XPProgressBarView_Previews: PreviewProvider {
	static var previews: some View {
		XPProgressBarView(xp: .constant(XP(total: 0, level: 0, levelXP: 0, levelXPMax: 0, progress: 0)))
	}
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 28.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct LegalNoticeView: View {
    var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text("Legal Notice").bold().font(.title)
			Text("Information in accordance with Section 5 TMG").padding(.bottom)
			Text("Adrian Baumgart\nKarl-Gehrig-Straße 2\n69226 Nußloch\nGermany").padding(.bottom)
			Text("Contact Information").bold().font(.headline)
			HStack {
				Text("Telephone:")
				Button(action: {
					let url = URL(string: "tel:+4915165909306")!
					if UIApplication.shared.canOpenURL(url) {
						UIApplication.shared.open(url)
					}
				}, label: {
					Text("+4915165909306").underline()
				})
			}
			HStack {
				Text("E-Mail:")
				Button(action: {
					let url = URL(string: "mailto:lea@abmgrt.dev")!
					if UIApplication.shared.canOpenURL(url) {
						UIApplication.shared.open(url)
					}
				}, label: {
					Text("lea@abmgrt.dev").underline()
				})
			}.padding(.bottom)
			Text("Disclaimer").bold().font(.headline)
			Text("Most of the content within this app is user-generated. We are not responsible for this content. If you want to repost an issue regarding this content, please contact Alles Support.")
			Spacer()
		}.padding(16).navigationBarTitle(Text("Legal Notice"), displayMode: .inline)
    }
}

struct LegalNoticeView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			LegalNoticeView()
		}
    }
}

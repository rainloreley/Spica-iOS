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
import KingfisherSwiftUI

var spicaAppCredits = [
	Credit(name: "Lea Baumgart", description: "iOS Developer", twitterURL: URL(string: "https://twitter.com/leabmgrt")!, allesUID: "87cd0529-f41b-4075-a002-059bf2311ce7", imageURL: URL(string: "https://avatar.alles.cc/87cd0529-f41b-4075-a002-059bf2311ce7")!),
	Credit(name: "Archie Baer", description: "Alles Founder", twitterURL: URL(string: "https://twitter.com/onlytruearchie")!, allesUID: "00000000-0000-0000-0000-000000000000", imageURL: URL(string: "https://avatar.alles.cc/00000000-0000-0000-0000-000000000000")!),
	Credit(name: "Jason", description: "Android Developer", twitterURL: URL(string: "https://twitter.com/jso_8910")!, allesUID: "0b528866-df2c-4323-9498-7b4b417b0023", imageURL: URL(string: "https://avatar.alles.cc/0b528866-df2c-4323-9498-7b4b417b0023")!),
	Credit(name: "David Muñoz", description: "Translator (Spanish)", twitterURL: URL(string: "https://twitter.com/Dmunozv04")!, allesUID: "a5f008b2-575b-4a56-944f-4ee46ad522d8", imageURL: URL(string: "https://crowdin-static.downloads.crowdin.com/avatar/13940729/small/bf4ab120766769e9c9deed4b51c2661c.jpg")!),
	Credit(name: "James Young", description: "Translator (French, Norwegian)", twitterURL: URL(string: "https://twitter.com/onlytruejames")!, allesUID: "af3a1a9e-b0e1-418e-8b4c-76605897eeab", imageURL: URL(string: "https://avatar.alles.cc/af3a1a9e-b0e1-418e-8b4c-76605897eeab")!),
	Credit(name: "@DaThinkingChair", description: "Translator (Spanish)", twitterURL: URL(string: "https://twitter.com/DaThinkingChair")!, imageURL: URL(string: "https://pbs.twimg.com/profile_images/1259314332950769666/UPvu5g-e_400x400.jpg")!),
	Credit(name: "Storm", description: "Translator (Norwegian)", twitterURL: URL(string: "https://twitter.com/StormLovesTech")!, allesUID: "43753811-5856-4d98-93a3-ed8763e9176e", imageURL: URL(string: "https://avatar.alles.cc/43753811-5856-4d98-93a3-ed8763e9176e")!),
	Credit(name: "primenate32", description: "Translator (Spanish)", twitterURL: URL(string: "https://twitter.com/n8_64")!, allesUID: "daf52a37-667a-4434-8dcc-c6fa1f9fa508", imageURL: URL(string: "https://pbs.twimg.com/profile_images/1312457889966182402/ygvafSTw_400x400.jpg")!),
	Credit(name: "grify", description: "Translator (Swedish)", twitterURL: URL(string: "https://twitter.com/GrifyDev")!, allesUID: "181cbcb1-5bf4-43f1-9ec9-0b36e67ab02d", imageURL: URL(string: "https://avatar.alles.cc/181cbcb1-5bf4-43f1-9ec9-0b36e67ab02d")!),
	Credit(name: "Hanna", description: "A lot of bug reports and suggestions", twitterURL: URL(string: "https://twitter.com/iHanna_01")!, allesUID: "5b0e1bcc-19b0-4c9e-9d98-b8fad3473920", imageURL: URL(string: "https://avatar.alles.cc/5b0e1bcc-19b0-4c9e-9d98-b8fad3473920")!),
]

struct CreditsView: View {
    var body: some View {
		Group {
			if #available(iOS 14.0, *) {
				List {
					CreditsSubView()
				}.listStyle(InsetGroupedListStyle())
			} else {
				List {
					CreditsSubView()
				}.listStyle(GroupedListStyle())
					.environment(\.horizontalSizeClass, .regular)
			}
		}.navigationBarTitle(Text("Credits"))
    }
}

struct CreditsSubView: View {
	
	var body: some View {
		ForEach(Array(spicaAppCredits.enumerated()), id: \.offset) { (index, credit) in
			if index == spicaAppCredits.count - 1 {
				Section(footer: VStack(alignment: .leading) {
					Text("Hello there! 👋").padding([.top, .bottom], 4)
			  Text("Thank you for reading this. Without these awesome people, this app wouldn't be possible!")
			  Text("Also thank you to everyone testing the app, giving feedback and reporting bugs!")
				}.padding(4)) {
					CreditCell(credit: credit)
				}
			}
			else {
				Section {
					CreditCell(credit: credit)
				}
			}
		}
		/*Section(footer: VStack(alignment: .leading) {
			Text("Hello there! 👋").padding([.top, .bottom], 4)
			Text("Thank you for reading this. Without these awesome people, this app wouldn't be possible!")
			Text("Also thank you to everyone testing the app, giving feedback and reporting bugs!")
		}) {
			
		}*/
	}
}

struct CreditCell: View {
	var credit: Credit
	var body: some View {
		HStack {
			KFImage(credit.imageURL).resizable().frame(width: 40, height: 40)
				.clipShape(Circle())
			VStack(alignment: .leading) {
				Text(credit.name).bold()
				Text(credit.description).foregroundColor(.secondary).font(.footnote)
			}
			Spacer()
		}.padding(4).contextMenu(ContextMenu(menuItems: {
			Button(action: {
				if UIApplication.shared.canOpenURL(credit.twitterURL) {
					UIApplication.shared.open(credit.twitterURL)
				}
			}, label: {
				HStack {
					Text("Twitter")
					Spacer()
					Image("twitter")
				}
			})
			if credit.allesUID != nil {
				Button(action: {
					let url = URL(string: "spica://user/\(credit.allesUID!)")!
					if UIApplication.shared.canOpenURL(url) {
						UIApplication.shared.open(url)
					}
				}, label: {
					HStack {
						Text("Micro")
						Spacer()
						Image(systemName: "circle")
					}
				})
			}
		})).onTapGesture {
			if credit.allesUID != nil {
				let url = URL(string: "spica://user/\(credit.allesUID!)")!
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url)
				}
			}
			else {
				if UIApplication.shared.canOpenURL(credit.twitterURL) {
					UIApplication.shared.open(credit.twitterURL)
				}
			}
		}
	}
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			CreditsSubView()
		}
    }
}

struct Credit: Identifiable {
	var id: UUID = UUID()
	var name: String
	var description: String
	var twitterURL: URL
	var allesUID: String?
	var imageURL: URL
}

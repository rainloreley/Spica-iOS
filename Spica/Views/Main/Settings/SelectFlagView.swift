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
import SwiftKeychainWrapper
import SPAlert

struct SelectFlagView: View {
    var body: some View {
		Group {
			if #available(iOS 14.0, *) {
				List {
					SelectFlagSubView()
				}.listStyle(InsetGroupedListStyle())
			} else {
				List {
					SelectFlagSubView()
				}.listStyle(GroupedListStyle())
					.environment(\.horizontalSizeClass, .regular)
			}
		}.navigationBarTitle(Text("Select a flag"))
    }
}

struct SelectFlagSubView: View {
	
	@State var errorMessage: String = ""
	@State var showError: Bool = false
	
	@State var flags = [
		Flag(name: "None", description: "Disable the flag around your profile picture", ring: .none),
		Flag(name: "Rainbow Pride Flag", description: "The rainbow pride flag", ring: .rainbow),
		Flag(name: "Transgender Pride Flag", description: "The transgender pride flag", ring: .trans),
		Flag(name: "Bisexual Pride Flag", description: "The bisexual pride flag", ring: .bisexual),
		Flag(name: "Pansexual Pride Flag", description: "The pansexual pride flag", ring: .pansexual),
		Flag(name: "Lesbian Pride Flag", description: "The lesbian pride flag", ring: .lesbian),
		Flag(name: "Asexual Pride Flag", description: "The asexual pride flag", ring: .asexual),
		Flag(name: "Genderqueer Pride Flag", description: "The genderqueer pride flag", ring: .genderqueer),
		Flag(name: "Genderfluid Pride Flag", description: "The genderfluid pride flag", ring: .genderfluid),
		Flag(name: "Agender Pride Flag", description: "The agender pride flag", ring: .agender),
		Flag(name: "Non-Binary Pride flag", description: "The non-binary pride flag", ring: .nonbinary),
	]
	
	var body: some View {
		Group {
			ForEach(Array(flags.enumerated()), id: \.offset) { (index, flag) in
				if index == flags.count - 1 {
					Section(footer: VStack(alignment: .leading) {
						Text("You can select a flag here, which will be shown around the profile picture on your profile page. It is visible to anyone else.")
						Text("Note: this is a Spica feature, so it'll only show if you use Spica 0.9.1 beta 16 or higher").padding(.bottom)
						Text("There is a ✨ special ✨ flag for people in \"Credits\". If you're mentioned there but you don't see the special flag, please contact me, thanks!")
					}.padding()) {
						FlagCell(flag: flag, errorMessage: $errorMessage, showError: $showError)
					}
				}
				else {
					Section {
						FlagCell(flag: flag, errorMessage: $errorMessage, showError: $showError)
					}
				}
			}
		}.onAppear(perform: {
			
			let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
			if spicaAppCredits.contains(where: { $0.allesUID == signedInID! }) && !flags.contains(where: { $0.ring == .supporter }) {
				flags.append(Flag(name: "Spica Supporter Flag", description: "A ✨ special ✨ flag because you helped developing Spica!", ring: .supporter))
			}
		}).alert(isPresented: $showError) {
			Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .cancel())
}
	}
}

struct FlagCell: View {
	
	var flag: Flag
	
	@Binding var errorMessage: String
	@Binding var showError: Bool
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("\(flag.name)").bold().font(.headline)
			Text("\(flag.description)").foregroundColor(.secondary).font(.footnote)
		}.padding(4).onTapGesture {
			let signedInID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
			FlagServerAPI.default.updateUserRing(flag.ring, id: signedInID!) { result in
				switch result {
				case let .failure(err):
					DispatchQueue.main.async {
						errorMessage = "The following error occurred:\n\(err.error.humanDescription)"
						showError = true
					}
				case .success:
					DispatchQueue.main.async {
						SPAlert.present(title: "Flag updated!", preset: .done)
					}
				}
			}
		}
	}
}

struct SelectFlagView_Previews: PreviewProvider {
    static var previews: some View {
        SelectFlagView()
    }
}

struct Flag: Identifiable {
	var id: UUID = UUID()
	var name: String
	var description: String
	var ring: ProfileRing
}

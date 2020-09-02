//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.09.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct MiniPostView: View {
    @ObservedObject var controller: MiniPostController
    var body: some View {
        Group {
            VStack(alignment: .leading) {
                HStack {
                    Image(uiImage: controller.post?.author?.image).resizable().frame(width: 40, height: 40, alignment: .center).cornerRadius(20)
                    Text("\((controller.post?.author!.nickname)!)\((controller.post?.author!.plus)! ? String("⁺") : String(""))").bold()
                    Spacer()
                }
                Text(controller.post?.content)
            }
        }.background(Color.clear).padding().overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        ).padding(4)
    }
}

struct MiniPostView_Previews: PreviewProvider {
    static var previews: some View {
        MiniPostView(controller: .init(post: MiniPost(id: "000", author: User(id: "87cd0529-f41b-4075-a002-059bf2311ce7", name: "Adrian", tag: "0001", nickname: "Adrian", plus: true, alles: true), content: "Hello World!")))
    }
}

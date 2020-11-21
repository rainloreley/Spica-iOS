//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI

struct CircularProgressBar: View {
    @ObservedObject var controller: ProgressBarController

    var lineWidth = CGFloat(8.0)

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(controller.color)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(controller.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(controller.color)
                .rotationEffect(Angle(degrees: 270.0))
                //.animation(.linear)
        }
    }
}

struct CircularProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressBar(controller: .init(progress: 0.5, color: .gray))
    }
}

//
//  CircularProgressBar.swift
//  Spica
//
//  Created by Adrian Baumgart on 05.07.20.
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
                .foregroundColor(self.controller.color)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.controller.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(self.controller.color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)

            /* Text(String(format: "%.0f %%", min(self.controller.progress, 1.0)*100.0))
             .font(.largeTitle)
             .bold() */
        }
    }
}

struct CircularProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressBar(controller: .init(progress: 0.5, color: .gray))
    }
}

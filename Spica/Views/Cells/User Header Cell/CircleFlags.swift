//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 24.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import SwiftUI

struct RainbowFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0.166 * 0, to: (0.166 * 0) + 0.166)
                .stroke(Color.red, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.166 * 1, to: (0.166 * 1) + 0.166)
                .stroke(Color.orange, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.166 * 2, to: (0.166 * 2) + 0.166)
                .stroke(Color.yellow, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.166 * 3, to: (0.166 * 3) + 0.166)
                .stroke(Color.green, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.166 * 4, to: (0.166 * 4) + 0.166)
                .stroke(Color.blue, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.166 * 5, to: 1)
                .stroke(Color.purple, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct TransFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0.2 * 0, to: (0.2 * 0) + 0.2)
                .stroke(Color("flag_trans_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 1, to: (0.2 * 1) + 0.2)
                .stroke(Color("flag_trans_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 2, to: (0.2 * 2) + 0.2)
                .stroke(Color.white, lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 3, to: (0.2 * 3) + 0.2)
                .stroke(Color("flag_trans_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 4, to: (0.2 * 4) + 0.2)
                .stroke(Color("flag_trans_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct BisexualFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.4)
                .stroke(Color("flag_bisexual_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.4, to: 0.6)
                .stroke(Color("flag_bisexual_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.6, to: 1)
                .stroke(Color("flag_bisexual_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct PansexualFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.3333)
                .stroke(Color("flag_pansexual_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.3333, to: 0.6666)
                .stroke(Color("flag_pansexual_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.6666, to: 1)
                .stroke(Color("flag_pansexual_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct LesbianFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0.1428 * 0, to: (0.1428 * 0) + 0.1428)
                .stroke(Color("flag_lesbian_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 1, to: (0.1428 * 1) + 0.1428)
                .stroke(Color("flag_lesbian_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 2, to: (0.1428 * 2) + 0.1428)
                .stroke(Color("flag_lesbian_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 3, to: (0.1428 * 3) + 0.1428)
                .stroke(Color("flag_lesbian_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 4, to: (0.1428 * 4) + 0.1428)
                .stroke(Color("flag_lesbian_stripe5"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 5, to: (0.1428 * 5) + 0.1428)
                .stroke(Color("flag_lesbian_stripe6"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 6, to: 1)
                .stroke(Color("flag_lesbian_stripe7"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct AsexualFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.25)
                .stroke(Color("flag_asexual_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.25, to: 0.5)
                .stroke(Color("flag_asexual_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.5, to: 0.75)
                .stroke(Color("flag_asexual_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.75, to: 1)
                .stroke(Color("flag_asexual_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct GenderqueerFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.3333)
                .stroke(Color("flag_genderqueer_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.3333, to: 0.6666)
                .stroke(Color("flag_genderqueer_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.6666, to: 1)
                .stroke(Color("flag_genderqueer_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct GenderfluidFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0.2 * 0, to: (0.2 * 0) + 0.2)
                .stroke(Color("flag_genderfluid_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 1, to: (0.2 * 1) + 0.2)
                .stroke(Color("flag_genderfluid_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 2, to: (0.2 * 2) + 0.2)
                .stroke(Color("flag_genderfluid_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 3, to: (0.2 * 3) + 0.2)
                .stroke(Color("flag_genderfluid_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.2 * 4, to: (0.2 * 4) + 0.2)
                .stroke(Color("flag_genderfluid_stripe5"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct AgenderFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0.1428 * 0, to: (0.1428 * 0) + 0.1428)
                .stroke(Color("flag_agender_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 1, to: (0.1428 * 1) + 0.1428)
                .stroke(Color("flag_agender_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 2, to: (0.1428 * 2) + 0.1428)
                .stroke(Color("flag_agender_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 3, to: (0.1428 * 3) + 0.1428)
                .stroke(Color("flag_agender_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 4, to: (0.1428 * 4) + 0.1428)
                .stroke(Color("flag_agender_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 5, to: (0.1428 * 5) + 0.1428)
                .stroke(Color("flag_agender_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.1428 * 6, to: 1)
                .stroke(Color("flag_agender_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct NonbinaryFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.25)
                .stroke(Color("flag_nonbinary_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.25, to: 0.5)
                .stroke(Color("flag_nonbinary_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.5, to: 0.75)
                .stroke(Color("flag_nonbinary_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.75, to: 1)
                .stroke(Color("flag_nonbinary_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

struct SpicaSupporterFlagCircle: ViewModifier {
    var addShadow: Bool
    func body(content: Content) -> some View {
        return content
            .overlay(Circle()

                .trim(from: 0, to: 0.25)
                .stroke(Color("flag_supporter_stripe1"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.25, to: 0.5)
                .stroke(Color("flag_supporter_stripe2"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.5, to: 0.75)
                .stroke(Color("flag_supporter_stripe3"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
            .overlay(Circle()

                .trim(from: 0.75, to: 1)
                .stroke(Color("flag_supporter_stripe4"), lineWidth: addShadow ? 4 : 2)
                .rotationEffect(.degrees(-90), anchor: .center)
                .shadow(radius: addShadow ? 8 : 0)
            )
    }
}

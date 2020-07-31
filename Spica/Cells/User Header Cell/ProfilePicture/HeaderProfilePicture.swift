//
//  HeaderProfilePicture.swift
//  Spica
//
//  Created by Adrian Baumgart on 31.07.20.
//

import SwiftUI
import Combine

struct HeaderProfilePicture: View {
	
	@ObservedObject var controller: HeaderProfilePictureController
	
    var body: some View {
		Group {
			Image(uiImage: controller.profilePicture)
				.resizable()
				.clipped()
				.frame(width: 120, height: 120, alignment: .center)
				.clipShape(Circle())
				.shadow(radius: 10)
				.overlay(Circle()
							
							.trim(from: 0, to: controller.grow ? 1 : 0)
							.stroke(controller.isOnline ? Color.green : Color.gray, lineWidth: 3)
							.rotationEffect(.degrees(90), anchor: .center)
							.animation(.easeInOut(duration: 1))
							.shadow(radius: 10)
						 
					)
					/*.onAppear {
						self.grow.toggle()
					}*/
		}
		.background(Color.clear)
		
    }
}

struct HeaderProfilePicture_Previews: PreviewProvider {
    static var previews: some View {
		HeaderProfilePicture(controller: .init(isOnline: true, profilePicture: UIImage(systemName: "person.circle")!, grow: true))
    }
}

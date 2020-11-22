//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 20.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation

func analyzeLink(_ url: URL) -> URL {
	var components = url.pathComponents
	if components.first == "/" { components.remove(at: 0) }
	
	if url.host == "micro.alles.cx" {
		
		if components.count > 0 {
			if components.first == "followers" {
				return URL(string: "spica://followers")!
			}
			else if components.first == "following" {
				return URL(string: "spica://following")!
			}
			else if components.first == "p" && components.count == 2 {
				return URL(string: "spica://post/\(components[1])")!
			}
			else {
				return URL(string: "spica://user/\(String(components.first!))")!
			}
		}
		else {
			return url
		}
	}
	else {
		return url
	}
	
	
}

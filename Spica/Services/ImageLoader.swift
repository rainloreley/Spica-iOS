//
//  ImageLoader.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Foundation
import UIKit

let imageCache = NSCache<NSString, UIImage>()

public class ImageLoader {
    static let `default` = ImageLoader()
    public func loadImageFromInternet(url: URL) -> UIImage {
		
		if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
			print("Cached: \(url.absoluteString)")
			return cachedImage
		}
		else {
			
			print("Not Cached: \(url.absoluteString)")
			let tempImg: UIImage?
			let data = try? Data(contentsOf: url)
			if data != nil {
				tempImg = UIImage(data: data!)
				imageCache.setObject(tempImg!, forKey: url.absoluteString as NSString)
				print("Now Cached: \(url.absoluteString)")
			} else {
				tempImg = UIImage(systemName: "person")
			}
			
			return tempImg!
		}
		
        
    }
}

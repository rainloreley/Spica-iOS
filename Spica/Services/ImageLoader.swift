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
    public static func loadImageFromInternet(url: URL) -> UIImage {
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            return cachedImage
        } else {
            let tempImg: UIImage?
            let data = try? Data(contentsOf: url)
            if let data = data {
                tempImg = UIImage(data: data)
                imageCache.setObject(tempImg!, forKey: url.absoluteString as NSString)
            } else {
                tempImg = UIImage(systemName: "person.circle")
            }

            return tempImg!
        }
    }
}

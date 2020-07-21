//
//  ImageLoader.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Foundation
import UIKit
import Cache

let imageCache = NSCache<NSString, UIImage>()

public class ImageLoader {
    public static func loadImageFromInternet(url: URL) -> UIImage {
		
		let diskConfig = DiskConfig(name: "SpicaImageCache")
		let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)

		let storage = try? Storage(
		  diskConfig: diskConfig,
		  memoryConfig: memoryConfig,
		  transformer: TransformerFactory.forCodable(ofType: Data.self) // Storage<User>
		)
		
		if let cachedImage = try? storage!.entry(forKey: url.absoluteString)/*imageCache.object(forKey: url.absoluteString as NSString)*/ {
			return UIImage(data: cachedImage.object)!
        } else {
        let tempImg: UIImage?
        let data = try? Data(contentsOf: url)
        if let data = data {
            tempImg = UIImage(data: data)
			try? storage?.setObject((tempImg?.pngData())!, forKey: url.absoluteString)
            //imageCache.setObject(tempImg!, forKey: url.absoluteString as NSString)
        } else {
            tempImg = UIImage(systemName: "person.circle")
        }

        return tempImg!
        }
    }
}

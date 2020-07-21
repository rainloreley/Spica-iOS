//
//  ImageLoader.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Foundation
import UIKit
import Cache
import RealmSwift

let imageCache = NSCache<NSString, UIImage>()

public class ImageLoader {
    public static func loadImageFromInternet(url: URL) -> UIImage {
	
		let realm = try! Realm()
		
		if let cachedImage = realm.objects(CacheImage.self).filter("id == \"\(url.absoluteString)\"").first {
			return UIImage(data: cachedImage.image!)!
        } else {
        let tempImg: UIImage?
        let data = try? Data(contentsOf: url)
        if let data = data {
            tempImg = UIImage(data: data)
			let cachedImage = CacheImage()
			cachedImage.id = url.absoluteString
			cachedImage.image = tempImg?.pngData()
			
			try! realm.write {
				realm.add(cachedImage)
			}
        } else {
            tempImg = UIImage(systemName: "person.circle")
        }
        return tempImg!
        }
    }
}

class CacheImage: Object {
	@objc dynamic var id: String = ""
	@objc dynamic var image: Data? = nil
}

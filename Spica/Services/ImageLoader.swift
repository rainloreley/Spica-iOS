//
//  ImageLoader.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import Cache
import Foundation
import RealmSwift
import UIKit
import Unrealm

let imageCache = NSCache<NSString, UIImage>()

public class ImageLoader {
    public static func loadImageFromInternet(url: URL) -> UIImage {
        let realm = try! Realm()
        if let cachedImage = realm.objects(CacheImage.self).filter({ $0.id == url.absoluteString }).first {
            return UIImage(data: cachedImage.image!)!
        } else {
            let tempImg: UIImage?
            let data = try? Data(contentsOf: url)
            if let data = data {
                tempImg = UIImage(data: data)
                let cachedImage = CacheImage(id: url.absoluteString, image: data)

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

struct CacheImage: Realmable {
    init() {
        id = ""
        image = nil
    }

    var id: String = ""
    var image: Data?

    init(id: String, image: Data) {
        self.id = id
        self.image = image
    }
}

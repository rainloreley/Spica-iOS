//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 30.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Cache
import Combine
import Foundation
import UIKit

let imageCache = NSCache<NSString, UIImage>()

public class ImageLoader {
    static let `default` = ImageLoader()
    // private var subscriptions = Set<AnyCancellable>()

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

    public static func loadImageFromInternetNew(url: URL) -> Future<UIImage, Error> {
        Future<UIImage, Error> { promise in
            DispatchQueue.global(qos: .background).async {
                if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
                    return promise(.success(cachedImage))
                } else {
                    let tempImg: UIImage?
                    let data = try? Data(contentsOf: url)
                    if let data = data {
                        tempImg = UIImage(data: data)
                        imageCache.setObject(tempImg!, forKey: url.absoluteString as NSString)
                    } else {
                        tempImg = UIImage(systemName: "person.circle")
                    }
                    return promise(.success(tempImg!))
                }
            }
        }
    }
}

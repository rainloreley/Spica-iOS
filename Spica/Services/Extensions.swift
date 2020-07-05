//
//  Extensions.swift
//  Spica
//
//  Created by Adrian Baumgart on 29.06.20.
//

import Foundation
import SwiftUI

extension Date {
    static func ISOStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return dateFormatter.string(from: date).appending("Z")
    }

    static func dateFromISOString(string: String) -> Date? {
        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        return dateFormatter.date(from: string)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

func countString(number: Int, singleText: String, multiText: String) -> String {
    if number == 1 {
        return "\(number) \(singleText)"
    } else {
        return "\(number) \(multiText)"
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == utf16.count
        } else {
            return false
        }
    }
}

func removeSpecialCharsFromString(text: String) -> String {
    let okayChars: Set<Character> =
        Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890@")
    return String(text.filter { okayChars.contains($0) })
}

extension UIImageView {
    func downloadImageFrom(link: String, contentMode: UIView.ContentMode) {
        URLSession.shared.dataTask(with: NSURL(string: link)! as URL, completionHandler: {
            (data, _, _) -> Void in
            DispatchQueue.main.async {
                self.contentMode = contentMode
                if let data = data { self.image = UIImage(data: data)! }
            }
		}).resume()
    }
}

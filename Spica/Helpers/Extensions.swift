//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 29.06.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import LocalAuthentication
import SwiftUI

func biometricType() -> BiometricType {
    let authContext = LAContext()
    if #available(iOS 11, *) {
        _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch authContext.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touch
        case .faceID:
            return .face
        }
    } else {
        return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
    }
}

enum BiometricType {
    case none
    case touch
    case face
}

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

func countString(number: Int, singleText: String, multiText: String, includeNumber: Bool) -> String {
    if number == 1 {
        if includeNumber {
            return "\(number) \(singleText)"
        } else {
            return "\(singleText)"
        }
    } else {
        if includeNumber {
            return "\(number) \(multiText)"
        } else {
            return "\(multiText)"
        }
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
            return match.range.length == utf16.count
        } else {
            return false
        }
    }
}

func removeSpecialCharsFromString(text: String) -> String {
    let okayChars: Set<Character> =
        Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890@-%")
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

func isValidUrl(url: String) -> Bool {
    let urlRegEx = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
    let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx)
    let result = urlTest.evaluate(with: url)
    return result
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0 ..< length).map { _ in letters.randomElement()! })
}

extension UserDefaults {
    open func setStruct<T: Codable>(_ value: T?, forKey defaultName: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: defaultName)
    }

    open func structData<T>(_ type: T.Type, forKey defaultName: String) -> T? where T: Decodable {
        guard let encodedData = data(forKey: defaultName) else {
            return nil
        }

        return try! JSONDecoder().decode(type, from: encodedData)
    }

    open func setStructArray<T: Codable>(_ value: [T], forKey defaultName: String) {
        let data = value.map { try? JSONEncoder().encode($0) }

        set(data, forKey: defaultName)
    }

    open func structArrayData<T>(_ type: T.Type, forKey defaultName: String) -> [T] where T: Decodable {
        guard let encodedData = array(forKey: defaultName) as? [Data] else {
            return []
        }

        return encodedData.map { try! JSONDecoder().decode(type, from: $0) }
    }
}

extension UITableView {
    func setEmptyMessage(message: String, subtitle: String) {
        let backView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        let messageLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.text = message
            label.textColor = .label
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 25)
            return label
        }()

        let subtitleLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.text = subtitle
            label.textColor = .tertiaryLabel
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 20)
            return label
        }()

        backgroundView = backView

        backView.addSubview(messageLabel)
        backView.addSubview(subtitleLabel)

        messageLabel.snp.makeConstraints { make in
            make.centerX.equalTo(backView.snp.centerX)
            make.centerY.equalTo(backView.snp.centerY)
            make.leading.equalTo(backView.snp.leading)
            make.trailing.equalTo(backView.snp.trailing)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(backView.snp.centerX)
            make.top.equalTo(messageLabel.snp.bottom)
            make.leading.equalTo(backView.snp.leading)
            make.trailing.equalTo(backView.snp.trailing)
        }

        separatorStyle = .none
    }

    func restore() {
        backgroundView = nil
        separatorStyle = .singleLine
    }
}

func hexStringToUIColor(hex: String) -> UIColor {
    var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if cString.hasPrefix("#") {
        cString.remove(at: cString.startIndex)
    }

    if cString.count != 6 {
        return UIColor.gray
    }

    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

func arraysAreSame(first aFirstArray: [String], second aSecondArray: [String]) -> Bool {
    return aFirstArray.sorted() == aSecondArray.sorted()
}

extension UserDefaults {
    func colorForKey(key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }
        return color
    }

    func setColor(color: UIColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color) as NSData?
        }
        set(colorData, forKey: key)
    }
}

extension Color {
    func uiColor() -> UIColor {
        let components = self.components()
        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }

    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

        let result = scanner.scanHexInt64(&hexNumber)
        if result {
            r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x0000_00FF) / 255
        }
        return (r, g, b, a)
    }
}

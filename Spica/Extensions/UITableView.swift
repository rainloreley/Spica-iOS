//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Foundation
import UIKit

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
            make.leading.equalTo(backView.snp.leading).offset(8)
            make.trailing.equalTo(backView.snp.trailing).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(backView.snp.centerX)
            make.top.equalTo(messageLabel.snp.bottom)
            make.leading.equalTo(backView.snp.leading).offset(8)
            make.trailing.equalTo(backView.snp.trailing).offset(-8)
        }

        separatorStyle = .none
    }

    func restore() {
        backgroundView = nil
        separatorStyle = .singleLine
    }
}

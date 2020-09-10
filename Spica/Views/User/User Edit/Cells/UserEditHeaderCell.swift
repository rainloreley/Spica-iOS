//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 16.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class UserEditHeaderCell: UITableViewCell {
    var user: User! {
        didSet {
            pfpImageView.image = user.image!
            if user.plus {
                let font: UIFont = UIFont.boldSystemFont(ofSize: 18)

                let fontSuper: UIFont = UIFont.boldSystemFont(ofSize: 12)
                let attrDisplayName = NSMutableAttributedString(string: "\(user.name)+", attributes: [.font: font])
                attrDisplayName.setAttributes([.font: fontSuper, .baselineOffset: 10], range: NSRange(location: user.name.count, length: 1))

                displaynameLabel.attributedText = attrDisplayName
            } else {
                displaynameLabel.text = user.name
            }

            usernameLabel.text = "\(user.name)#\(user.tag)"
        }
    }

    var pfpImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.hero.id = "userPfpImageView"
        imgView.layer.cornerRadius = 50
        return imgView
    }()

    private var displaynameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Display Name"
        label.textAlignment = .center
        label.hero.id = "userDisplaynameLabel"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()

    private var usernameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "username"
        label.hero.id = "userUsernameLabel"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        hero.isEnabled = true

        contentView.addSubview(pfpImageView)
        contentView.addSubview(displaynameLabel)
        contentView.addSubview(usernameLabel)

        usernameLabel.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(22)
        }

        displaynameLabel.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX)
            make.bottom.equalTo(usernameLabel.snp.top)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.height.equalTo(30)
        }

        pfpImageView.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX)
            make.top.equalTo(contentView.snp.top).offset(40)
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.bottom.equalTo(displaynameLabel.snp.top).offset(-16)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

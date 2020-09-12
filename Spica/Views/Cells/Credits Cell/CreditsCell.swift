//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class CreditsCell: UITableViewCell {
    var creditUser: Credit! {
        didSet {
            nameLabel.text = creditUser.name
            roleLabel.text = creditUser.role
            pfpImageView.image = creditUser.image
        }
    }

    private var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Name"
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()

    private var roleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Role"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()

    var pfpImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = 20
        return imgView
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(nameLabel)
        contentView.addSubview(roleLabel)
        contentView.addSubview(pfpImageView)
		
		let contextInteraction = UIContextMenuInteraction(delegate: self)
		contentView.addInteraction(contextInteraction)

        pfpImageView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }

        nameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY).offset(-8)
            make.leading.equalTo(pfpImageView.snp.trailing).offset(8)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }

        roleLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom)
            make.leading.equalTo(pfpImageView.snp.trailing).offset(8)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension CreditsCell: UIContextMenuInteractionDelegate {
	func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in

			self.makeContextMenu()
		})
	}

	func makeContextMenu() -> UIMenu {
		var actionsArray = [UIAction]()

		let twitter = UIAction(title: "Twitter", image: UIImage(named: "twitter")) { _ in
			let url = URL(string: self.creditUser.twitterURL)
			if UIApplication.shared.canOpenURL(url!) {
				UIApplication.shared.open(url!)
			}
		}

		actionsArray.append(twitter)
		
		if creditUser.allesUID != nil {
			let micro = UIAction(title: "Micro", image: UIImage(systemName: "circle")) { _ in
				let url = URL(string: "spica://user/\(self.creditUser.allesUID!)")
				if UIApplication.shared.canOpenURL(url!) {
					UIApplication.shared.open(url!)
				}
			}
			actionsArray.append(micro)
		}

		return UIMenu(title: "Credit", children: actionsArray)
	}
}

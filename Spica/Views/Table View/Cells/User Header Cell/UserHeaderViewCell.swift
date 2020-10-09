//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SwiftUI
import UIKit

class UserHeaderViewCell: UITableViewCell {
	var headerView: UIView!

	var headerController = UserHeaderViewController()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		backgroundView = nil
		backgroundColor = .clear
		contentView.backgroundColor = .clear
		headerView = UIHostingController(rootView: UserHeaderView(controller: headerController)).view
		headerView.backgroundColor = .clear
		contentView.addSubview(headerView)
		headerView.snp.makeConstraints { make in
			make.top.equalTo(contentView.snp.top)
			make.leading.equalTo(contentView.snp.leading)
			make.bottom.equalTo(contentView.snp.bottom)
			make.trailing.equalTo(contentView.snp.trailing)
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

//
//  UserHeaderViewCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.08.20.
//

import UIKit
import SwiftUI
import Combine

class UserHeaderViewCell: UITableViewCell {
	
	var headerView: UIView!
	
	var headerController = UserHeaderViewController()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		headerView = UIHostingController(rootView: UserHeaderView(controller: headerController)).view
		contentView.addSubview(headerView)
		headerView.snp.makeConstraints { (make) in
			make.top.equalTo(contentView.snp.top)
			make.leading.equalTo(contentView.snp.leading)
			make.bottom.equalTo(contentView.snp.bottom)
			make.trailing.equalTo(contentView.snp.trailing)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  AncestorPostDividerCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 15.07.20.
//

import UIKit

class AncestorPostDividerCell: UITableViewCell {
	
	
	private var divider: UIView = {
		let view = UIView(frame: .zero)
		view.backgroundColor = UIColor(named: "UserBackground")
		view.layer.cornerRadius = 7.0
		return view
	}()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		contentView.addSubview(divider)
		contentView.backgroundColor = .clear
		
		divider.snp.makeConstraints { (make) in
			make.width.equalTo(10)
			make.height.equalTo(80)
			make.top.equalTo(contentView.snp.top).offset(16)
			make.bottom.equalTo(contentView.snp.bottom).offset(-16)
			make.center.equalTo(contentView.snp.center)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

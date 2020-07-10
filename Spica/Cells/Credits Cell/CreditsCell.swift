//
//  CreditsCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 10.07.20.
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
        // Initialization code
    }
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		contentView.addSubview(nameLabel)
		contentView.addSubview(roleLabel)
		contentView.addSubview(pfpImageView)
		
		pfpImageView.snp.makeConstraints { (make) in
			make.centerY.equalTo(contentView.snp.centerY)
			make.left.equalTo(contentView.snp.left).offset(16)
			make.width.equalTo(40)
			make.height.equalTo(40)
		}
		
		nameLabel.snp.makeConstraints { (make) in
			make.centerY.equalTo(contentView.snp.centerY).offset(-8)
			make.left.equalTo(pfpImageView.snp.right).offset(8)
			make.right.equalTo(contentView.snp.right).offset(-16)
		}
		
		roleLabel.snp.makeConstraints { (make) in
			make.top.equalTo(nameLabel.snp.bottom)
			make.left.equalTo(pfpImageView.snp.right).offset(8)
			make.right.equalTo(contentView.snp.right).offset(-16)
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

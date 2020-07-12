//
//  UserHeaderCellView.swift
//  Spica
//
//  Created by Adrian Baumgart on 12.07.20.
//

import UIKit
import SwiftKeychainWrapper

class UserHeaderCellView: UITableViewCell {
	
	var user: User! {
		didSet {
			pfpImageView.image = user.image

            let rectShape = CAShapeLayer()
            rectShape.bounds = contentView.frame
            rectShape.position = contentView.center
            rectShape.path = UIBezierPath(roundedRect: contentView.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 40, height: 40)).cgPath

            contentView.layer.backgroundColor = UIColor(named: "UserBackground")?.cgColor
            contentView.layer.mask = rectShape
            if user.isOnline {
                onlineIndicatorView.backgroundColor = .systemGreen
            } else {
                onlineIndicatorView.backgroundColor = .gray
            }

            if user.isPlus {
                // let font:UIFont? = UIFont(name: "Helvetica", size:20)
                let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
                let attrDisplayName = NSMutableAttributedString(string: "\(user.displayName)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: user.displayName.count, length: 1))

                displaynameLabel.attributedText = attrDisplayName
            } else {
                displaynameLabel.text = user.displayName
            }

            usernameLabel.text = "@\(user.username)"
            //followsYouLabel.text = user.followsMe ? "Follows you" : ""

            let boldFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
            let notBoldFont: UIFont = UIFont.systemFont(ofSize: 16)
            let attrRubies = NSMutableAttributedString(string: countString(number: user.rubies, singleText: "Ruby", multiText: "Rubies"), attributes: [.font: notBoldFont])
            attrRubies.setAttributes([.font: boldFont], range: NSRange(location: 0, length: String(user.rubies).count))
            rubiesLabel.attributedText = attrRubies

            let attrFollowers = NSMutableAttributedString(string: countString(number: user.followers, singleText: "Follower", multiText: "Followers"), attributes: [.font: notBoldFont])
            attrFollowers.setAttributes([.font: boldFont], range: NSRange(location: 0, length: String(user.followers).count))
            followerCountLabel.attributedText = attrFollowers
            aboutTextView.text = user.about
			
			let signedInUsername = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")

            if signedInUsername != user.username {
                followButton.isEnabled = true
                if user.isFollowing {
                    followButton.setTitle("Following", for: .normal)
                    followButton.backgroundColor = .systemBlue
                    followButton.setTitleColor(.white, for: .normal)
                    followButton.layer.cornerRadius = 12
                } else {
                    followButton.setTitle("Follow", for: .normal)
                    followButton.backgroundColor = .white
                    followButton.setTitleColor(.systemBlue, for: .normal)
                    followButton.layer.cornerRadius = 12
                }

				//followButton.addTarget(self, action: #selector(followUnfollowUser), for: .touchUpInside)
            } else {
                followButton.backgroundColor = .clear
                followButton.setTitleColor(.clear, for: .normal)
                followButton.setTitle("", for: .normal)
                followButton.isEnabled = false
            }
		}
	}

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	var pfpImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = 50
        return imgView
    }()
	
	private var displaynameLabel: UILabel = {
		let label = UILabel(frame: .zero)
		label.text = "Display Name"
		label.textAlignment = .center
		label.font = .boldSystemFont(ofSize: 18)
		return label
	}()
	
	private var usernameLabel: UILabel = {
		let label = UILabel(frame: .zero)
		label.text = "username"
		label.textAlignment = .center
		label.textColor = .secondaryLabel
		return label
	}()
	
	private var onlineIndicatorView: UIView = {
		let view = UIView(frame: .zero)
		view.layer.cornerRadius = 8.0
		return view
	}()
	
	private var followsYouLabel: UILabel = {
		let label = UILabel(frame: .zero)
		label.textColor = .tertiaryLabel
		label.textAlignment = .center
		label.text = "Follows you"
		return label
	}()
	
	private var followerCountLabel: UILabel = {
		let label = UILabel(frame: .zero)
		label.text = "Follower"
		label.textAlignment = .right
		return label
	}()
	
	private var rubiesLabel: UILabel = {
		let label = UILabel(frame: .zero)
		label.text = "Rubies"
		label.textAlignment = .left
		return label
	}()
	
	private var aboutTextView: UITextView = {
		let textView = UITextView(frame: .zero)
		textView.text = "About"
		textView.font = .systemFont(ofSize: 14)
		textView.textAlignment = .center
		textView.backgroundColor = .clear
		return textView
	}()
	
	var followButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("Follow", for: .normal)
		return button
	}()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		contentView.addSubview(pfpImageView)
		contentView.addSubview(displaynameLabel)
		contentView.addSubview(usernameLabel)
		contentView.addSubview(onlineIndicatorView)
		contentView.addSubview(followsYouLabel)
		contentView.addSubview(followerCountLabel)
		contentView.addSubview(rubiesLabel)
		contentView.addSubview(aboutTextView)
		contentView.addSubview(followButton)
		
		contentView.snp.makeConstraints { (make) in
			make.top.equalTo(self.snp.top)
			make.leading.equalTo(self.snp.leading)
			make.trailing.equalTo(self.snp.trailing)
			make.bottom.equalTo(self.snp.bottom)
			make.height.equalTo(400)
		}
		
		followButton.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX)
			make.width.equalTo(120)
			make.height.equalTo(40)
			make.bottom.equalTo(contentView.snp.bottom).offset(-16)
		}
		
		aboutTextView.snp.makeConstraints { (make) in
			make.bottom.equalTo(followButton.snp.top).offset(-16)
			make.leading.equalTo(contentView.snp.leading).offset(32)
			make.trailing.equalTo(contentView.snp.trailing).offset(-32)
			make.height.equalTo(60)
			//make.height.greaterThanOrEqualTo(30)
			make.centerX.equalTo(contentView.snp.centerX)
		}
		
		followerCountLabel.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX).offset(-70)
			make.width.equalTo(120)
			make.height.equalTo(22)
			make.bottom.equalTo(aboutTextView.snp.top).offset(-16)
		}
		
		rubiesLabel.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX).offset(70)
			make.width.equalTo(120)
			make.height.equalTo(22)
			make.bottom.equalTo(aboutTextView.snp.top).offset(-16)
		}
		
		followsYouLabel.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX)
			make.bottom.equalTo(rubiesLabel.snp.top).offset(-8)
			make.leading.equalTo(contentView.snp.leading).offset(16)
			make.trailing.equalTo(contentView.snp.trailing).offset(-16)
			make.height.equalTo(22)
			make.width.equalTo(120)
		}
		
		usernameLabel.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX)
			make.bottom.equalTo(followsYouLabel.snp.top).offset(-8)
			//make.width.equalTo(120)
			/*make.leading.equalTo(contentView.snp.leading).offset(16)
			make.trailing.equalTo(contentView.snp.trailing).offset(-16)*/
			make.height.equalTo(22)
		}
		
		onlineIndicatorView.snp.makeConstraints { (make) in
			make.height.equalTo(16)
			make.width.equalTo(16)
			make.leading.equalTo(usernameLabel.snp.trailing).offset(16)
			//make.top.equalTo(displaynameLabel.snp.bottom)
			make.centerY.equalTo(usernameLabel.snp.centerY)
		}
		
		displaynameLabel.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX)
			make.bottom.equalTo(usernameLabel.snp.top)
			make.leading.equalTo(contentView.snp.leading).offset(16)
			make.trailing.equalTo(contentView.snp.trailing).offset(-16)
			make.height.equalTo(30)
		}
		
		pfpImageView.snp.makeConstraints { (make) in
			make.centerX.equalTo(contentView.snp.centerX)
			make.top.equalTo(contentView.snp.top).offset(64)
			make.width.equalTo(100)
			make.height.equalTo(100)
			make.bottom.equalTo(displaynameLabel.snp.top).offset(-32)
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

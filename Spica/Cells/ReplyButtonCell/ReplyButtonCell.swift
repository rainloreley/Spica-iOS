//
//  ReplyButtonCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
//

import UIKit

class ReplyButtonCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    var replyBtn: UIButton! = {
        var button = UIButton(type: .system)
        button.backgroundColor = UIColor(named: "PostButtonColor")
        button.setTitle(SLocale(.REPLY_ACTION), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(replyBtn)
        replyBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.top.equalTo(contentView.snp.top).offset(8)
            make.bottom.equalTo(contentView.snp.bottom).offset(-8)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

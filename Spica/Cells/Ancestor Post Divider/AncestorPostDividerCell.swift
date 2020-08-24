//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 15.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class AncestorPostDividerCell: UITableViewCell {
    private var divider: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(named: "PostDivider")
        view.layer.cornerRadius = 4.0
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(divider)
        contentView.backgroundColor = .clear

        divider.snp.makeConstraints { make in
            make.width.equalTo(10)
            make.height.equalTo(60)
            make.top.equalTo(contentView.snp.top).offset(16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.center.equalTo(contentView.snp.center)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

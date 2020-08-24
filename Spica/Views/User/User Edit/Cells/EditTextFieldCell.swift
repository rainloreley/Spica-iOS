//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 16.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import UIKit

class EditTextFieldCell: UITableViewCell, UITextFieldDelegate {
    var placeholder: String! {
        didSet {
            textField.placeholder = placeholder
        }
    }

    var textChanged: ((String) -> Void)?

    func textChanged(action: @escaping (String) -> Void) {
        textChanged = action
    }

    @objc func textViewDidChange(_: UITextField) {
        textChanged?(textField.text!)
    }

    var textField: UITextField = {
        var textField = UITextField(frame: .zero)
        textField.placeholder = ""

        textField.borderStyle = .roundedRect
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textField.addTarget(self, action: #selector(textViewDidChange(_:)), for: .editingChanged)

        contentView.addSubview(textField)

        textField.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(8)
            make.bottom.equalTo(contentView.snp.bottom).offset(-8)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.height.equalTo(50)
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

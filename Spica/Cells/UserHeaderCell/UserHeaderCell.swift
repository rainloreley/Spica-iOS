//
//  UserHeaderCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import UIKit

class UserHeaderCell: UITableViewCell {
    @IBOutlet var pfpView: UIImageView!
    @IBOutlet var displayNameLbl: UILabel!
    @IBOutlet var usernameLbl: UILabel!
    @IBOutlet var followerLbl: UILabel!
    @IBOutlet var rubiesLbl: UILabel!
    @IBOutlet var aboutTextView: UITextView!
    @IBOutlet var followBtn: UIButton!
    @IBOutlet var onlineIndicatorView: UIView!
    @IBOutlet var followsYouLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

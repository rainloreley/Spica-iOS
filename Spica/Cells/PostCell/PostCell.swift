//
//  PostCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import UIKit

class PostCell: UITableViewCell {
    @IBOutlet var upvoteBtn: UIButton!
    @IBOutlet var downvoteBtn: UIButton!
    @IBOutlet var voteLvl: UILabel!
    @IBOutlet var pfpView: UIImageView!
    @IBOutlet var displayNameLbl: UILabel!
    @IBOutlet var usernameLbl: UILabel!
    @IBOutlet var dateLbl: UILabel!
    @IBOutlet var repliesLbl: UILabel!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var attachedImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func buildCell(cell: PostCell, post: Post) -> PostCell {
        cell.selectionStyle = .none
        cell.pfpView.image = post.author.image
        if post.author.isPlus {
            // let font:UIFont? = UIFont(name: "Helvetica", size:20)
            let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

            let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
            let attrDisplayName = NSMutableAttributedString(string: "\(post.author.displayName)+", attributes: [.font: font!])
            attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: post.author.displayName.count, length: 1))

            cell.displayNameLbl.attributedText = attrDisplayName
        } else {
            cell.displayNameLbl.text = post.author.displayName
        }
        cell.usernameLbl.text = "@\(post.author.username)"
        cell.voteLvl.text = "\(post.score)"
        cell.dateLbl.text = globalDateFormatter.string(from: post.date)
        cell.repliesLbl.text = countString(number: post.repliesCount, singleText: "Reply", multiText: "Replies")
        cell.contentTextView.text = post.content

        if post.voteStatus == 1 {
            cell.upvoteBtn.setTitleColor(.systemGreen, for: .normal)
            cell.downvoteBtn.setTitleColor(.gray, for: .normal)
        } else if post.voteStatus == -1 {
            cell.downvoteBtn.setTitleColor(.systemRed, for: .normal)
            cell.upvoteBtn.setTitleColor(.gray, for: .normal)
        } else {
            cell.upvoteBtn.setTitleColor(.systemBlue, for: .normal)
            cell.downvoteBtn.setTitleColor(.systemBlue, for: .normal)
        }

        if post.image != nil {
            cell.attachedImageView.image = post.image

            let imageWidth = post.image!.size.width
            //let myImageHeight = post.image!.size.height
            //let myViewWidth = cell.attachedImageView.frame.size.width

            //let ratio = myViewWidth / myImageWidth
            //let scaledHeight = myImageHeight * ratio

            let imageHeight = post.image?.size.height

            // cell.attachedImageView.image = UIImage(systemName: "person")
            cell.attachedImageView.snp.makeConstraints { make in
                make.width.equalTo(imageWidth)
                make.height.equalTo(imageHeight! / 6)
            }
        } else {
            cell.attachedImageView.image = nil
            cell.attachedImageView.snp.makeConstraints { make in
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
        }
        return cell
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

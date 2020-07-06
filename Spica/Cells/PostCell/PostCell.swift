//
//  PostCell.swift
//  Spica
//
//  Created by Adrian Baumgart on 30.06.20.
//

import UIKit

protocol PostCellDelegate {
    func selectedUser(username: String, indexPath: IndexPath)
    func selectedURL(url: String, indexPath: IndexPath)
    func selectedPost(post: String, indexPath: IndexPath)
}

class PostCell: UITableViewCell, UITextViewDelegate {
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

    var delegate: PostCellDelegate!
    private var indexPath: IndexPath!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func buildCell(post: Post, indexPath: IndexPath) {
        self.indexPath = indexPath
        selectionStyle = .none
        pfpView.image = post.author.image

        if post.image != nil {
            attachedImageView.image = post.image!

            attachedImageView.snp.makeConstraints { make in
                //	make.width.equalTo(self.contentView.snp.width).offset(-80)
                make.height.equalTo((post.image?.size.height)! / 3)
            }
        }

        /* let imageHeight = cell.attachedImageView.image?.size.height
         cell.attachedImageView.snp.makeConstraints { make in

         		make.width.equalTo(self.contentView.snp.width).offset(-80)
         	make.height.equalTo((post.image?.size.height ?? 0) / 3)
         		 //make.height.equalTo(imageHeight!)
         	 } */

        if post.author.isPlus {
            // let font:UIFont? = UIFont(name: "Helvetica", size:20)
            let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

            let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
            let attrDisplayName = NSMutableAttributedString(string: "\(post.author.displayName)+", attributes: [.font: font!])
            attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: post.author.displayName.count, length: 1))

            displayNameLbl.attributedText = attrDisplayName
        } else {
            displayNameLbl.text = post.author.displayName
        }
        usernameLbl.text = "@\(post.author.username)"
        voteLvl.text = "\(post.score)"
        dateLbl.text = globalDateFormatter.string(from: post.date)
        repliesLbl.text = countString(number: post.repliesCount, singleText: "Reply", multiText: "Replies")
        // contentTextView.text = post.content
        contentTextView.delegate = self

        let attributedText = NSMutableAttributedString(string: "")

        let normalFont: UIFont? = UIFont.systemFont(ofSize: 15)

        let splitContent = post.content.split(separator: " ")
        for word in splitContent {
            if word.hasPrefix("@"), word.count > 1 {
                let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                // let username = String(word).replacingOccurrences(of: ".", with: "")
                let username = removeSpecialCharsFromString(text: String(word))
                print("username: \(username)")
                selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: username.count))
                // selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
                selectablePart.addAttribute(.link, value: "user:\(username)", range: NSRange(location: 0, length: username.count))
                attributedText.append(selectablePart)
            } else if word.hasPrefix("%"), word.count > 1 {
                let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                // let username = String(word).replacingOccurrences(of: ".", with: "")

                print("madePost: \(word)")

                selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
                // selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
                let postID = word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]
                selectablePart.addAttribute(.link, value: "post:\(postID)", range: NSRange(location: 0, length: selectablePart.length - 1))
                attributedText.append(selectablePart)
            } else if String(word).isValidURL, word.count > 1 {
                let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
                // selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
                selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
                attributedText.append(selectablePart)
            } else {
                attributedText.append(NSAttributedString(string: word + " "))
            }
        }

        attributedText.addAttributes([.font: normalFont!], range: NSRange(location: 0, length: attributedText.length))
        contentTextView.attributedText = attributedText
        contentView.resignFirstResponder()

        if post.voteStatus == 1 {
            upvoteBtn.setTitleColor(.systemGreen, for: .normal)
            downvoteBtn.setTitleColor(.gray, for: .normal)
        } else if post.voteStatus == -1 {
            downvoteBtn.setTitleColor(.systemRed, for: .normal)
            upvoteBtn.setTitleColor(.gray, for: .normal)
        } else {
            upvoteBtn.setTitleColor(.systemBlue, for: .normal)
            downvoteBtn.setTitleColor(.systemBlue, for: .normal)
        }

        /* if post.imageURL != nil {
         //cell.attachedImageView.image = post.image

         cell.attachedImageView.image = UIImage(systemName: "person") //ImageLoader.default.loadImageFromInternet(url: post.imageURL!)
         let imageHeight = cell.attachedImageView.image?.size.height

         // cell.attachedImageView.image = UIImage(systemName: "person")
         cell.attachedImageView.snp.makeConstraints { make in
         	make.width.equalTo(100)
         	make.height.equalTo(100)
         	/* make.width.equalTo(self.contentView.snp.width).offset(-80)
         	make.height.equalTo(imageHeight! / 3) */
         	//make.height.equalTo(imageHeight!)
         }

         //let imageWidth = post.image!.size.width

         //let myImageHeight = post.image!.size.height
         //let myViewWidth = cell.attachedImageView.frame.size.width

         //let ratio = myViewWidth / myImageWidth
         //let scaledHeight = myImageHeight * ratio

         //let imageHeight = post.image?.size.height

         } else {
         //cell.attachedImageView.image = nil
         /* cell.attachedImageView.snp.makeConstraints { make in
             make.width.equalTo(0)
             make.height.equalTo(0)
         } */
         } */
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func textView(_: UITextView, shouldInteractWith URL: URL, in _: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            let stringURL = URL.absoluteString

            if stringURL.hasPrefix("user:@") {
                let username = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 6) ..< stringURL.endIndex]
                delegate.selectedUser(username: String(username), indexPath: indexPath)
            } else if stringURL.hasPrefix("url:") {
                let selURL = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 4) ..< stringURL.endIndex]
                delegate.selectedURL(url: String(selURL), indexPath: indexPath)
            } else if stringURL.hasPrefix("post:") {
                let postID = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 5) ..< stringURL.endIndex]
                delegate.selectedPost(post: String(postID), indexPath: indexPath)
            }
        }
        return false
    }
}

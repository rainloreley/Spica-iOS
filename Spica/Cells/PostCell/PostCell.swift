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

	func buildCell(cell: PostCell, post: Post, indexPath: IndexPath) -> PostCell {
		self.indexPath = indexPath
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
        //cell.contentTextView.text = post.content
		cell.contentTextView.delegate = self
		
		let attributedText = NSMutableAttributedString(string: "")
		
		let normalFont: UIFont? = UIFont.systemFont(ofSize: 15)
		
		
		let splitContent = post.content.split(separator: " ")
			for word in splitContent {
				
				if word.hasPrefix("@") {
					let selectablePart = NSMutableAttributedString(string: String(word) + " ")
					//let username = String(word).replacingOccurrences(of: ".", with: "")
					let username = removeSpecialCharsFromString(text: String(word))
					print("username: \(username)")
					selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: username.count))
					//selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
					selectablePart.addAttribute(.link, value: "user:\(username)", range: NSRange(location: 0, length: username.count))
					attributedText.append(selectablePart)
				}
				else if word.hasPrefix("%") {
					let selectablePart = NSMutableAttributedString(string: String(word) + " ")
					//let username = String(word).replacingOccurrences(of: ".", with: "")
					
					print("madePost: \(word)")
					
					selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
					//selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
					let postID = word[word.index(word.startIndex, offsetBy: 1)..<word.endIndex]
					selectablePart.addAttribute(.link, value: "post:\(postID)", range: NSRange(location: 0, length: selectablePart.length - 1))
					attributedText.append(selectablePart)
				}
				else if String(word).isValidURL {
					let selectablePart = NSMutableAttributedString(string: String(word) + " ")
					selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
					//selectablePart.addAttribute(.underlineColor, value: UIColor.blue, range: NSRange(location: 0, length: selectablePart.length))
					selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
					attributedText.append(selectablePart)
				}
				
				else {
					attributedText.append(NSAttributedString(string: word + " "))
				}
			}
		
		
		attributedText.addAttributes([.font: normalFont!], range: NSRange(location: 0, length: attributedText.length))
		cell.contentTextView.attributedText = attributedText
		cell.contentView.resignFirstResponder()

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

            //let imageWidth = post.image!.size.width
			
            //let myImageHeight = post.image!.size.height
            //let myViewWidth = cell.attachedImageView.frame.size.width

            //let ratio = myViewWidth / myImageWidth
            //let scaledHeight = myImageHeight * ratio

            let imageHeight = post.image?.size.height

            // cell.attachedImageView.image = UIImage(systemName: "person")
            cell.attachedImageView.snp.makeConstraints { make in
				make.width.equalTo(contentView.snp.width).offset(-80)
				make.height.equalTo(imageHeight! / 3)
                //make.height.equalTo(imageHeight!)
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
	

	func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		
		let stringURL = URL.absoluteString
		
		if stringURL.hasPrefix("user:@") {
			let username = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 6)..<stringURL.endIndex]
			delegate.selectedUser(username: String(username), indexPath: self.indexPath)
			
		}
		else if stringURL.hasPrefix("url:") {
			let selURL = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 4)..<stringURL.endIndex]
			delegate.selectedURL(url: String(selURL), indexPath: self.indexPath)
		}
		else if stringURL.hasPrefix("post:") {
			
			let postID = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 5)..<stringURL.endIndex]
			delegate.selectedPost(post: String(postID), indexPath: self.indexPath)
		}
		return false
	}
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 07.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import Kingfisher
import UIKit
import Lightbox
import SPAlert

protocol PostCellDelegate {
	func clickedImage(controller: LightboxController)
	func clickedUser(user: User)
}

class PostCell: UITableViewCell {
    private var subscriptions = Set<AnyCancellable>()
	var delegate: PostCellDelegate?

    var post: Post? {
        didSet {
            // Load post into view

            profilePictureImageView?.image = post?.author.profilePicture
            if post?.author.plus == true {
                let font: UIFont? = usernameLabel.font

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
                let attrDisplayName = NSMutableAttributedString(string: "\(post!.author.nickname)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: (post?.author.nickname.count)!, length: 1))

                usernameLabel.attributedText = attrDisplayName
            } else {
                usernameLabel.text = post?.author.name
            }

            postContentTextView.text = post?.content

            profilePictureImageView?.kf.setImage(with: post?.author.profilePictureUrl)
            postImageView.kf.setImage(with: post?.imageurl)
			
			let profilePictureTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickedUser))
			
			profilePictureImageView!.isUserInteractionEnabled = true
			profilePictureImageView!.addGestureRecognizer(profilePictureTapGestureRecognizer)
			
			let postimageViewTapGestureGecognizer = UITapGestureRecognizer(target: self, action: #selector(clickImage))
			
			if post?.imageurl != nil {
				postImageView.isUserInteractionEnabled = true
				postImageView.addGestureRecognizer(postimageViewTapGestureGecognizer)
			}
			else {
				postImageView.isUserInteractionEnabled = false
				postImageView.removeGestureRecognizer(postimageViewTapGestureGecognizer)
			}

            postLinkLabel.text = post?.url?.absoluteString

            updateVoteScore(score: post!.score, vote: post!.vote)

            let linkGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openLink))

            if post?.url != nil {
                postLinkBackgroundView.snp.remakeConstraints { make in
                    make.height.equalTo(35)
                    make.leading.equalTo(contentView.snp.leading).offset(16)
                    make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                    make.top.equalTo(postImageView.snp.bottom).offset(12)
                    make.bottom.equalTo(upvoteButton.snp.top).offset(-3)
                }
                postLinkBackgroundView.addGestureRecognizer(linkGestureRecognizer)
                postLinkLabel.addGestureRecognizer(linkGestureRecognizer)
                postLinkBackgroundView.isUserInteractionEnabled = true
                postLinkLabel.isUserInteractionEnabled = true
            } else {
                postLinkBackgroundView.snp.remakeConstraints { make in
                    make.height.equalTo(0)
                    make.leading.equalTo(contentView.snp.leading)
                    make.trailing.equalTo(contentView.snp.trailing)
                    make.top.equalTo(postImageView.snp.bottom).offset(12)
                    make.bottom.equalTo(upvoteButton.snp.top).offset(-3)
                }
                postLinkBackgroundView.removeGestureRecognizer(linkGestureRecognizer)
                postLinkLabel.removeGestureRecognizer(linkGestureRecognizer)
                postLinkBackgroundView.isUserInteractionEnabled = false
                postLinkLabel.isUserInteractionEnabled = false
            }

            /*let postdateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM dd, yyyy HH:mm", options: 0, locale: Locale.current) // "MMM dd, yyyy HH:mm"
                formatter.timeZone = TimeZone.current
                formatter.doesRelativeDateFormatting = true
                return formatter
            }()*/

            postdateLabel.text = RelativeDateTimeFormatter().localizedString(for: post!.createdAt, relativeTo: Date()) // postdateFormatter.string(from: post!.createdAt)
            replycountLabel.text = String((post?.children.count)!)
            if post?.interactions != nil {
                interactioncountLabel.text = String((post?.interactions)!)
                interactioncountLabel.isHidden = false
                interactionCountIcon.isHidden = false
            } else {
                interactioncountLabel.isHidden = true
                interactionCountIcon.isHidden = true
                interactioncountLabel.text = ""
            }
        }
    }
	
	@objc func clickedUser() {
		if post != nil {
			delegate?.clickedUser(user: post!.author)
		}
	}
	
	@objc func clickImage() {
		if let image = postImageView.image {
			let images = [
				LightboxImage(image: image, text: postContentTextView.attributedText.string)]
			
			
			let controller = LightboxController(images: images)
			controller.dynamicBackground = true
			let saveBtn: UIButton = {
				let btn = UIButton(type: .system)
				btn.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
				btn.addTarget(self, action: #selector(saveImage), for: .touchUpInside)
				btn.tintColor = .white
				return btn
			}()
			
			controller.headerView.addSubview(saveBtn)
			saveBtn.snp.makeConstraints { make in
				// make.top.equalTo(controller.headerView.snp.top).offset(-2)
				make.centerY.equalTo(controller.headerView.closeButton.snp.centerY)
				make.leading.equalTo(controller.headerView.snp.leading).offset(8)
				make.width.equalTo(50)
				make.height.equalTo(50)
			}
			delegate?.clickedImage(controller: controller)
		}
	}
	
	@objc func saveImage() {
		if let image = postImageView.image {
			UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
		}
	}

    @objc func openLink() {
        if post?.url != nil {
            if UIApplication.shared.canOpenURL(post!.url!) {
                UIApplication.shared.open(post!.url!)
            }
        }
    }

    func updateVoteScore(score: Int, vote: Int) {
        postScoreLabel.text = String(score)
        if vote == 1 {
            upvoteButton.setTitleColor(.systemGreen, for: .normal)
            downvoteButton.setTitleColor(.systemGray, for: .normal)
        } else if vote == -1 {
            upvoteButton.setTitleColor(.systemGray, for: .normal)
            downvoteButton.setTitleColor(.systemRed, for: .normal)
        } else {
            upvoteButton.setTitleColor(.systemBlue, for: .normal)
            downvoteButton.setTitleColor(.systemBlue, for: .normal)
        }
    }

    func remakeImageView() {
        /* if postImageView.image != nil && post?.imageurl != nil {
         	//postImageView.image = post?.image
         	postImageView.snp.remakeConstraints { (make) in
         		make.height.equalTo(postImageView.image!.size.height)
         		make.leading.equalTo(contentView.snp.leading).offset(16)
         		make.trailing.equalTo(contentView.snp.trailing).offset(-16)
         		make.top.equalTo(postContentTextView.snp.bottom).offset(6)
         		make.bottom.equalTo(postLinkBackgroundView.snp.top).offset(-6)
         	}
         }
         else {
         	postImageView.image = UIImage()
         	postImageView.snp.remakeConstraints { (make) in
         		make.height.equalTo(0)
         		make.leading.equalTo(contentView.snp.leading)
         		make.trailing.equalTo(contentView.snp.trailing)
         		make.top.equalTo(postContentTextView.snp.bottom).offset(6)
         		make.bottom.equalTo(postLinkBackgroundView.snp.top).offset(-6)
         	}
         } */
    }

    // User
    @IBOutlet var profilePictureImageView: UIImageView?
    @IBOutlet var usernameLabel: UILabel!

    // Content
    @IBOutlet var postContentTextView: UITextView!
    @IBOutlet var postImageView: UIImageView!

    // Links
    @IBOutlet var postLinkBackgroundView: UIView!
    @IBOutlet var postLinkLabel: UILabel!

    // Voting
    @IBOutlet var postScoreLabel: UILabel!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!

    // Stats
    @IBOutlet var postdateLabel: UILabel!
    @IBOutlet var replycountLabel: UILabel!
    @IBOutlet var interactioncountLabel: UILabel!
    @IBOutlet var interactionCountIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func upvoteAction(_: Any) {
        vote(.upvote)
    }

    @IBAction func downvoteAction(_: Any) {
        vote(.downvote)
    }

    func vote(_ vote: VoteType) {
        VotePost.default.vote(post: post!, vote: vote)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    MicroAPI.default.errorHandling(error: err, caller: self.contentView)
					// AllesAPI.default.errorHandling(error: err, caller: self.view)

                default: break
                }
            } receiveValue: { [unowned self] in
                post?.score = $0.score
                post?.vote = $0.status
            }.store(in: &subscriptions)
    }
}

extension PostCell: UIImagePickerControllerDelegate {
	@objc func image(_: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer) {
			if let error = error {
				SPAlert.present(title: "Error", message: error.localizedDescription, preset: .error)

			} else {
				SPAlert.present(title: "Photo saved!", preset: .done)
			}
		}
}

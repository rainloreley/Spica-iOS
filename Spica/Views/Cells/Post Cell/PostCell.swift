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
import Lightbox
import SPAlert
import SwiftKeychainWrapper
import UIKit

protocol PostCellDelegate {
    func clickedImage(controller: LightboxController)
    func replyToPost(_ id: String)
    func reloadData()
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

            postContentTextView.attributedText = parseStringIntoAttributedString(post!.content)
            postContentTextView.delegate = self
            postContentTextView.isUserInteractionEnabled = true
            postContentTextView.delaysContentTouches = false
            postContentTextView.isSelectable = true

            profilePictureImageView?.kf.setImage(with: post?.author.profilePictureUrl)
            postImageView.kf.setImage(with: post?.imageurl)

            let profilePictureTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickedUser))

            profilePictureImageView!.isUserInteractionEnabled = true
            profilePictureImageView!.addGestureRecognizer(profilePictureTapGestureRecognizer)

            let postimageViewTapGestureGecognizer = UITapGestureRecognizer(target: self, action: #selector(clickImage))

            if post?.imageurl != nil {
                postImageView.isUserInteractionEnabled = true
                postImageView.addGestureRecognizer(postimageViewTapGestureGecognizer)
            } else {
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

            let contextInteraction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(contextInteraction)
        }
    }

    func parseStringIntoAttributedString(_ text: String) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: "")
        let normalFont: UIFont? = UIFont.systemFont(ofSize: UIFont.systemFontSize)

        let content = text.replacingOccurrences(of: "\n", with: " \n ")

        let splittedContent = content.split(separator: " ")

        for word in splittedContent {
            if String(word).isValidURL, word.count > 1 {
                let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
                selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
                attributedText.append(selectablePart)
            } else {
                if word == "\n" {
                    attributedText.append(NSAttributedString(string: "\n"))
                } else {
                    attributedText.append(NSAttributedString(string: word + " "))
                }
            }
        }
        attributedText.addAttributes([.font: normalFont!, .foregroundColor: UIColor.label], range: NSRange(location: 0, length: attributedText.length))
        return attributedText
    }

    @objc func clickedUser() {
        if post != nil {
            delegate?.clickedUser(user: post!.author)
        }
    }

    @objc func clickImage() {
        if let image = postImageView.image {
            let images = [
                LightboxImage(image: image, text: postContentTextView.attributedText.string),
            ]

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

extension PostCell: UITextViewDelegate {
    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            let stringURL = url.absoluteString
            if stringURL.hasPrefix("url:") {
                var selURL = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 4) ..< stringURL.endIndex]
                if !selURL.starts(with: "https://"), !selURL.starts(with: "http://") {
                    selURL = "https://" + selURL
                }
                let adaptedURL = URL(string: String(selURL))
                if UIApplication.shared.canOpenURL(adaptedURL!) {
                    UIApplication.shared.open(adaptedURL!)
                }
            } else if stringURL.isValidURL {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        }
        return false
    }
}

extension PostCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
            self.makeContextMenu()
		})
    }

    func makeContextMenu() -> UIMenu {
        var actions = [UIAction]()

        let copyID = UIAction(title: "Copy ID", image: UIImage(systemName: "doc.on.doc")) { [self] _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = post?.id
            SPAlert.present(title: "Copied", preset: .done)
        }

        actions.append(copyID)

        let reply = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { [self] _ in
            self.delegate?.replyToPost(post!.id)
        }

        actions.append(reply)

        let bookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")

        let isBookmarked = bookmarks.contains(where: { $0.id == post!.id })

        let bookmark = UIAction(title: isBookmarked ? "Remove Bookmark" : "Add Bookmark", image: isBookmarked ? UIImage(systemName: "bookmark.slash") : UIImage(systemName: "bookmark")) { [self] _ in

            if isBookmarked {
                // Delete bookmark

                var currentBookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")
                if let index = currentBookmarks.firstIndex(where: { $0.id == post?.id }) {
                    currentBookmarks.remove(at: index)
                    UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
                    SPAlert.present(title: "Removed!", preset: .done)
                    self.delegate?.reloadData()
                } else {
                    SPAlert.present(title: "An error occurred", preset: .error)
                }
            } else {
                // Add bookmark

                var currentBookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")
                currentBookmarks.append(StoredBookmark(id: post!.id, added: Date()))
                UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
                SPAlert.present(title: "Added!", preset: .done)
                self.delegate?.reloadData()
            }

            // self.delegate.editBookmark(id: self.post!.id, action: bookmarks.contains(where: { $0.id == self.post!.id }) ? .remove : .add)
        }

        actions.append(bookmark)

        let userID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

        if post?.author.id == userID! {
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                EZAlertController.alert("Delete post?", message: "Are you sure you want to delete your post? It'll be gone forever (a very long time)", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, index in
                    guard index == 1 else { return }

                    MicroAPI.default.deletePost(post!.id)
                        .receive(on: RunLoop.main)
                        .sink {
                            switch $0 {
                            case let .failure(err):
                                EZAlertController.alert("Error", message: "The following error occurred:\n\n\(err.error.name)")
                            default: break
                            }
                        } receiveValue: { _ in
                            SPAlert.present(title: "Deleted", preset: .done)
                            self.delegate?.reloadData()
                        }.store(in: &subscriptions)
                }
            }
            actions.append(delete)
        }

        return UIMenu(title: "Post", children: actions)
    }
}

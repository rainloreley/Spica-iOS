//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 05.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import KMPlaceholderTextView
import Lightbox
import SwiftKeychainWrapper
import SwiftUI
import UIKit

// https://github.com/devxoul/UITextView-Placeholder

protocol PostCellViewDelegate {
    func copyPostID(id: String)
    func deletePost(id: String)

    func replyToPost(id: String)

    func repost(id: String, uid: String)

    func clickedOnImage(controller: LightboxController)
    func saveImage(image: UIImage?)

    func editBookmark(id: String, action: BookmarkAction)

    func clickedOnMiniPost(id: String, miniPost: MiniPost)
}

enum BookmarkAction {
    case add, remove
}

class PostCellView: UITableViewCell, UITextViewDelegate {
    var delegate: PostCellViewDelegate!
    var indexPath: IndexPath!
    private var subscriptions = Set<AnyCancellable>()
    private var miniPostController = MiniPostController(post: nil)

    var post: Post? {
        didSet {
            pfpImageView.image = post?.author?.image
            contentTextView.isUserInteractionEnabled = true
            contentTextView.delaysContentTouches = false
            contentTextView.isScrollEnabled = false
            contentTextView.isEditable = false
            contentTextView.isUserInteractionEnabled = true
            contentTextView.isSelectable = true

            if post?.author?.plus == true {
                let font: UIFont? = UIFont.boldSystemFont(ofSize: 18)

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: 12)
                let attrDisplayName = NSMutableAttributedString(string: "\(post!.author!.nickname)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: (post?.author!.nickname.count)!, length: 1))

                displaynameLabel.attributedText = attrDisplayName
            } else {
                displaynameLabel.text = post!.author?.nickname
            }

            voteCountLabel.text = String(post!.score)
            contentTextView.delegate = self

            let attributedText = NSMutableAttributedString(string: "")

            let normalFont: UIFont? = UIFont.systemFont(ofSize: 15)

            let postContent = post?.content.replacingOccurrences(of: "\n", with: " \n ")

            let splitContent = postContent!.split(separator: " ")
            for word in splitContent {
                if word.hasPrefix("@"), word.count > 1 {
                    var userID = removeSpecialCharsFromString(text: String(word))
                    userID.remove(at: userID.startIndex)
                    let foundIndex = post?.mentionedUsers.firstIndex(where: { $0.id == userID })
                    if let index = foundIndex {
                        let mention = post?.mentionedUsers[index]
                        let selectablePart = NSMutableAttributedString(string: String(mention!.name) + " ")
                        selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                        selectablePart.addAttribute(.link, value: "spica://user/\(mention!.id)", range: NSRange(location: 0, length: selectablePart.length - 1))

                        attributedText.append(selectablePart)
                    } else {
                        attributedText.append(NSAttributedString(string: String(word
						) + " "))
                    }

                } else if word.hasPrefix("%"), word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")

                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                    let postID = word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]
                    selectablePart.addAttribute(.link, value: "spica://post/\(postID)", range: NSRange(location: 0, length: selectablePart.length - 1))

                    attributedText.append(selectablePart)
                } else if String(word).isValidURL, word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")
                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

                    selectablePart.addAttribute(.link, value: "url:\(word)", range: NSRange(location: 0, length: selectablePart.length - 1))
                    attributedText.append(selectablePart)
                } else if word.hasPrefix("#"), word.count > 1 {
                    let selectablePart = NSMutableAttributedString(string: String(word) + " ")

                    selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))

					let tag = removeSpecialCharsFromString(text: String(word[word.index(word.startIndex, offsetBy: 1) ..< word.endIndex]))
                    selectablePart.addAttribute(.link, value: "spica://tag/\(tag)", range: NSRange(location: 0, length: selectablePart.length - 1))
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
            contentTextView.attributedText = attributedText
            dateLabel.text = globalDateFormatter.string(from: post!.created)
            replyCountLabel.text = countString(number: post!.children_count, singleText: SLocale(.REPLY_SINGULAR), multiText: SLocale(.REPLY_PLURAL), includeNumber: true)
            interactionsLabel.text = post?.interactions != nil ? countString(number: (post?.interactions!)!, singleText: "Interaction", multiText: "Interactions", includeNumber: true) : ""

            if post?.image != nil {
                mediaImageView.image = post?.image!
                mediaImageView.snp.remakeConstraints { make in
                    make.bottom.equalTo(linkLabel.snp.top).offset(-16)
                    make.height.equalTo(((post?.image!.size.height)!) / 3)
                    make.trailing.equalTo(self.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }

                let tap = UITapGestureRecognizer(target: self, action: #selector(clickImage))

                mediaImageView.isUserInteractionEnabled = true
                mediaImageView.addGestureRecognizer(tap)
            }

            if post?.url != nil {
                linkLabel.setTitle(" \(post!.url!) ", for: .normal)
                let linkInteraction = UIGestureRecognizer(target: self, action: #selector(openLink))
                linkBackgroundView.isUserInteractionEnabled = true
                linkLabel.isUserInteractionEnabled = true
                linkBackgroundView.addGestureRecognizer(linkInteraction)
                linkLabel.addTarget(self, action: #selector(openLink), for: .touchUpInside)
                linkLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(miniPostView.snp.top).offset(-16)
                    make.height.equalTo(32)
                    make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }
            } else {
                linkLabel.setTitle("", for: .normal)
                linkLabel.snp.remakeConstraints { make in
                    make.bottom.equalTo(miniPostView.snp.top).offset(-16)
                    make.height.equalTo(0)
                    make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }
            }

            let miniPostSwiftUIView = UIHostingController(rootView: MiniPostView(controller: miniPostController)).view
            miniPostSwiftUIView?.backgroundColor = .clear
            miniPostSwiftUIView?.tag = 294
            let miniPostTapGesture = UITapGestureRecognizer(target: self, action: #selector(clickMiniPost))

            if let mentionedPost = post?.mentionedPost {
                miniPostView.addSubview(miniPostSwiftUIView!)
                miniPostView.addGestureRecognizer(miniPostTapGesture)
                miniPostSwiftUIView?.snp.makeConstraints { make in
                    make.top.equalTo(miniPostView.snp.top)
                    make.leading.equalTo(miniPostView.snp.leading)
                    make.bottom.equalTo(miniPostView.snp.bottom)
                    make.trailing.equalTo(miniPostView.snp.trailing)
                }
                miniPostController.post = mentionedPost
                miniPostView.snp.remakeConstraints { make in
                    make.bottom.equalTo(dateLabel.snp.top).offset(-16)
                    make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }
            } else {
                miniPostView.removeGestureRecognizer(miniPostTapGesture)
                miniPostView.snp.remakeConstraints { make in
                    make.bottom.equalTo(dateLabel.snp.top).offset(-16)
                    make.height.equalTo(0)
                    make.trailing.equalTo(contentView.snp.trailing).offset(-16)
                    make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
                }
                miniPostView.viewWithTag(294)?.removeFromSuperview()
            }

            if post!.voted == 1 {
                upvoteButton.setTitleColor(.systemGreen, for: .normal)
                downvoteButton.setTitleColor(.gray, for: .normal)
            } else if post!.voted == -1 {
                downvoteButton.setTitleColor(.systemRed, for: .normal)
                upvoteButton.setTitleColor(.gray, for: .normal)
            } else {
                upvoteButton.setTitleColor(.systemBlue, for: .normal)
                downvoteButton.setTitleColor(.systemBlue, for: .normal)
            }

            let contextInteraction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(contextInteraction)
            moreImageView.isUserInteractionEnabled = true
        }
    }

    @objc func openLink() {
        if let url = post?.url {
            if UIApplication.shared.canOpenURL(URL(string: url)!) {
                UIApplication.shared.open(URL(string: url)!)
            }
        }
    }

    @objc func clickMiniPost() {
        delegate.clickedOnMiniPost(id: post!.mentionedPost!.id, miniPost: (post?.mentionedPost)!)
    }

    @objc func clickImage() {
        if let image = post?.image {
            let images = [
                LightboxImage(
                    image: image,
                    text: contentTextView.attributedText.string // post!.content
                ),
            ]

            LightboxConfig.CloseButton.text = SLocale(.CLOSE_ACTION)
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

            delegate.clickedOnImage(controller: controller)
        }
    }

    @objc func saveImage() {
        delegate.saveImage(image: post?.image)
    }

    var pfpImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        if #available(iOS 13.4, *) {
            imgView.addInteraction(UIPointerInteraction())
        }
        imgView.layer.cornerRadius = 20

        return imgView
    }()

    private var miniPostView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var displaynameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .boldSystemFont(ofSize: 17.0)
        label.textAlignment = .left
        label.textColor = .label
        label.text = "Display Name"
        label.numberOfLines = 0
        return label
    }()

    private var moreImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "ellipsis.circle"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()

    private var voteCountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    var upvoteButton: UIButton = {
        #if targetEnvironment(macCatalyst)
            var button = UIButton(type: .custom)
        #else
            var button = UIButton(type: .system)
        #endif
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 23)
        button.setTitleColor(.systemBlue, for: .normal)
        if #available(iOS 13.4, *) {
            button.isPointerInteractionEnabled = true
        }
        return button
    }()

    var downvoteButton: UIButton = {
        #if targetEnvironment(macCatalyst)
            var button = UIButton(type: .custom)
        #else
            var button = UIButton(type: .system)
        #endif
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 29)
        button.setTitleColor(.systemBlue, for: .normal)
        if #available(iOS 13.4, *) {
            button.isPointerInteractionEnabled = true
        }
        return button
    }()

    private var mediaImageView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var contentTextView: KMPlaceholderTextView = {
        let textView = KMPlaceholderTextView(frame: .zero)
        textView.textAlignment = .left
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.text = "Content"
        textView.dataDetectorTypes = [.link, .lookupSuggestion, .phoneNumber]
        textView.isOpaque = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        return textView
    }()

    private var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Date"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        return label
    }()

    private var replyCountLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Replies"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .right
        return label
    }()

    private var interactionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Interactions"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .right
        return label
    }()

    private var linkBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 8
        view.backgroundColor = .secondarySystemBackground
        return view
    }()

    private var linkLabel: UIButton = {
        let label = UIButton(type: .system)
        label.setTitle("Link", for: .normal)
        label.setTitleColor(.label, for: .normal)
        label.titleLabel?.font = .italicSystemFont(ofSize: 16)
        label.contentHorizontalAlignment = .leading
        label.layer.cornerRadius = 8
        label.backgroundColor = .tertiarySystemGroupedBackground
        label.titleLabel?.lineBreakMode = .byTruncatingTail
        if #available(iOS 13.4, *) {
            label.isPointerInteractionEnabled = true
        }
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(pfpImageView)
        contentView.addSubview(displaynameLabel)
        contentView.addSubview(upvoteButton)
        contentView.addSubview(downvoteButton)
        contentView.addSubview(voteCountLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(replyCountLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(mediaImageView)
        contentView.addSubview(linkLabel)
        contentView.addSubview(miniPostView)

        contentView.isUserInteractionEnabled = true

        isUserInteractionEnabled = true

        contentTextView.translatesAutoresizingMaskIntoConstraints = false

        voteCountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        upvoteButton.snp.makeConstraints { make in
            make.bottom.equalTo(voteCountLabel.snp.top)
            make.centerX.equalTo(voteCountLabel.snp.centerX)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        downvoteButton.snp.makeConstraints { make in
            make.top.equalTo(voteCountLabel.snp.bottom).offset(-8)
            make.centerX.equalTo(voteCountLabel.snp.centerX)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.width.equalTo(30)
        }

        pfpImageView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(upvoteButton.snp.trailing).offset(16)
            make.top.equalTo(contentView.snp.top).offset(16)
        }

        displaynameLabel.snp.makeConstraints { make in
            make.leading.equalTo(pfpImageView.snp.trailing).offset(16)
            make.centerY.equalTo(pfpImageView.snp.centerY).offset(-2)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.width.equalTo(contentView.frame.width / 2)
        }

        replyCountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.width.equalTo(contentView.frame.width / 2)
            make.height.equalTo(30)
            make.top.equalTo(miniPostView.snp.bottom)
        }

        miniPostView.snp.makeConstraints { make in
            make.bottom.equalTo(dateLabel.snp.top).offset(-16)
            make.height.equalTo(0)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
        }

        linkLabel.snp.makeConstraints { make in
            make.bottom.equalTo(miniPostView.snp.top).offset(-16)
            make.height.equalTo(32)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
        }

        mediaImageView.snp.makeConstraints { make in
            make.bottom.equalTo(linkLabel.snp.top).offset(-16)
            make.height.equalTo(32)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
        }

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(pfpImageView.snp.bottom).offset(16)
            make.leading.equalTo(voteCountLabel.snp.trailing).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.bottom.equalTo(mediaImageView.snp.top).offset(-16)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        contentTextView.isEditable = true
        contentTextView.isSelectable = true
        contentTextView.isMultipleTouchEnabled = true
    }

    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            let stringURL = url.absoluteString
			
			if stringURL.hasPrefix("spica://") {
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url)
				}
			}
			else if stringURL.hasPrefix("url:") {
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

extension PostCellView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in

            self.makeContextMenu()
        })
    }

    func makeContextMenu() -> UIMenu {
        var actionsArray = [UIAction]()

        let copyID = UIAction(title: SLocale(.COPY_ID), image: UIImage(systemName: "doc.on.doc")) { _ in
            self.delegate.copyPostID(id: self.post!.id)
        }

        actionsArray.append(copyID)

        let reply = UIAction(title: SLocale(.REPLY_ACTION), image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
            self.delegate.replyToPost(id: self.post!.id)
        }

        actionsArray.append(reply)

        let repost = UIAction(title: SLocale(.REPOST), image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.delegate.repost(id: self.post!.id, uid: self.post!.author!.id)
        }

        actionsArray.append(repost)

        let bookmarks = UserDefaults.standard.structArrayData(Bookmark.self, forKey: "savedBookmarks")

        let bookmark = UIAction(title: bookmarks.contains(where: { $0.id == post!.id }) ? SLocale(.REMOVE_BOOKMARK) : SLocale(.ADD_BOOKMARK), image: bookmarks.contains(where: { $0.id == post!.id }) ? UIImage(systemName: "bookmark.slash") : UIImage(systemName: "bookmark")) { _ in
            self.delegate.editBookmark(id: self.post!.id, action: bookmarks.contains(where: { $0.id == self.post!.id }) ? .remove : .add)
        }

        actionsArray.append(bookmark)

        let userID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

        if post?.author?.id == userID! {
            let delete = UIAction(title: SLocale(.DELETE_ACTION), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.delegate.deletePost(id: self.post!.id)
            }
            actionsArray.append(delete)
        }

        return UIMenu(title: SLocale(.POST_NOUN), children: actionsArray)
    }
}

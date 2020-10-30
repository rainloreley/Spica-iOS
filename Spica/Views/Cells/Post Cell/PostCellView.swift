//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 28.10.20.
//
// Licensed under the MIT License
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
    func clickedImage(_ controller: ImageDetailViewController)
    func openPostView(_ type: PostType, preText: String?, preLink: String?, parentID: String?)
    func reloadData()
    func clickedUser(user: User)
    func clickedLink(_ url: URL)
    func reloadCell(_ at: IndexPath)
}

class PostCellView: UITableViewCell {
    var delegate: PostCellDelegate?
    var indexPath: IndexPath!

    var post: Post? {
        didSet {
            profilePictureImageView.image = post?.author.profilePicture
            if post?.author.plus == true {
                let font: UIFont? = usernameLabel.font

                let fontSuper: UIFont? = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize)
                let attrDisplayName = NSMutableAttributedString(string: "\(post!.author.nickname)+", attributes: [.font: font!])
                attrDisplayName.setAttributes([.font: fontSuper!, .baselineOffset: 10], range: NSRange(location: (post?.author.nickname.count)!, length: 1))

                usernameLabel.attributedText = attrDisplayName
            } else {
                usernameLabel.text = post?.author.name
            }
            layoutUsernameLabel()

            postContentTextView.attributedText = parseStringIntoAttributedString(post!.content)
            postContentTextView.delegate = self
            postContentTextView.isUserInteractionEnabled = true
            postContentTextView.delaysContentTouches = false
            postContentTextView.isSelectable = true

            profilePictureImageView.kf.setImage(with: post?.author.profilePictureUrl)
            postImageView.kf.setImage(with: post?.imageurl, completionHandler: { [self] result in
                layoutPostImageView(height: postImageView.image != nil ? Int(postImageView.image!.size.height / 3) : 20)
                switch result {
                case .success:
                    delegate!.reloadCell(indexPath)
                case .failure:
                    break
                }
			})

            let profilePictureTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickedUser))

            profilePictureImageView.isUserInteractionEnabled = true
            profilePictureImageView.addGestureRecognizer(profilePictureTapGestureRecognizer)
            if #available(iOS 13.4, *) {
                profilePictureImageView.addInteraction(UIPointerInteraction())
            }

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
                layoutPostLinkBackgroundView(hidden: false, remake: true)
                postLinkBackgroundView.addGestureRecognizer(linkGestureRecognizer)
                if #available(iOS 13.4, *) {
                    postLinkBackgroundView.addInteraction(UIPointerInteraction())
                }
                postLinkLabel.addGestureRecognizer(linkGestureRecognizer)
                postLinkBackgroundView.isUserInteractionEnabled = true
                postLinkLabel.isUserInteractionEnabled = true
            } else {
                layoutPostLinkBackgroundView(hidden: true, remake: true)
                postLinkBackgroundView.removeGestureRecognizer(linkGestureRecognizer)
                postLinkLabel.removeGestureRecognizer(linkGestureRecognizer)
                postLinkBackgroundView.isUserInteractionEnabled = false
                postLinkLabel.isUserInteractionEnabled = false
            }

            postdateLabel.text = RelativeDateTimeFormatter().localizedString(for: post!.createdAt, relativeTo: Date())
            replycountLabel.text = String((post?.children.count)!)
            if post?.interactions != nil {
                interactioncountLabel.text = String((post?.interactions)!)
                interactioncountLabel.isHidden = false
                interactioncountIcon.isHidden = false
            } else {
                interactioncountLabel.isHidden = true
                interactioncountIcon.isHidden = true
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
            } else if String(word).starts(with: "@"), word.count > 1 {
                let filteredWord = String(word).removeSpecialChars
                let filteredWordWithoutAtSymbol = String(filteredWord[filteredWord.index(filteredWord.startIndex, offsetBy: 1) ..< filteredWord.endIndex])
                var nameToInsert = filteredWordWithoutAtSymbol
                if let index = post?.mentionedUsers.firstIndex(where: { $0.id == nameToInsert }) {
                    nameToInsert = (post?.mentionedUsers[index].name)!
                }
                let selectablePart = NSMutableAttributedString(string: String(word.replacingOccurrences(of: filteredWordWithoutAtSymbol, with: nameToInsert)) + " ")
                selectablePart.addAttribute(.underlineStyle, value: 1, range: NSRange(location: 0, length: selectablePart.length - 1))
                selectablePart.addAttribute(.link, value: "user:\(filteredWord[filteredWord.index(filteredWord.startIndex, offsetBy: 1) ..< filteredWord.endIndex])", range: NSRange(location: 0, length: selectablePart.length - 1))
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

            let controller = ImageDetailViewController(images: images)
            controller.dynamicBackground = true
            delegate?.clickedImage(controller)
        }
    }

    @objc func openLink() {
        if let url = post?.url {
            delegate?.clickedLink(url)
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

    var profilePictureImageView: UIImageView = {
        let imgView = UIImageView(image: UIImage(systemName: "person.circle"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = 20
        return imgView
    }()

    var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()

    var postContentTextView: UITextView = {
        let textView = UITextView()
        textView.textAlignment = .left
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.text = "Content"
        textView.dataDetectorTypes = [.link, .lookupSuggestion, .phoneNumber]
        textView.isOpaque = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isEditable = false
        textView.isPagingEnabled = false
        return textView
    }()

    var postImageView: UIImageView = {
        let imgView = UIImageView(image: UIImage())
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var postLinkBackgroundView: UIView = {
        let view = UIView(frame: .init(x: 0, y: 0, width: 30, height: 35))
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = 12
        return view
    }()

    var postLinkLabel: UILabel = {
        let label = UILabel()
        label.text = "https://abmgrt.dev"
        label.font = .italicSystemFont(ofSize: 16)
        return label
    }()

    var upvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 19)
        return button
    }()

    var postScoreLabel: UILabel = {
        let label = UILabel()
        label.text = "10"
        return label
    }()

    var downvoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        return button
    }()

    var interactioncountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    var interactioncountIcon: UIImageView = {
        let imgView = UIImageView(image: UIImage(systemName: "eye"))
        imgView.tintColor = .secondaryLabel
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var replycountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    var replycountIcon: UIImageView = {
        let imgView = UIImageView(image: UIImage(systemName: "message"))
        imgView.tintColor = .secondaryLabel
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var postdateLabel: UILabel = {
        let label = UILabel()
        label.text = "1 day ago"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(profilePictureImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(postContentTextView)
        contentView.addSubview(postImageView)
        contentView.addSubview(postLinkBackgroundView)
        postLinkBackgroundView.addSubview(postLinkLabel)
        contentView.addSubview(upvoteButton)
        contentView.addSubview(postScoreLabel)
        contentView.addSubview(downvoteButton)
        contentView.addSubview(postdateLabel)
        contentView.addSubview(replycountIcon)
        contentView.addSubview(replycountLabel)
        contentView.addSubview(interactioncountIcon)
        contentView.addSubview(interactioncountLabel)

        upvoteButton.addTarget(self, action: #selector(upvoteAction), for: .touchUpInside)
        downvoteButton.addTarget(self, action: #selector(downvoteAction), for: .touchUpInside)

        layoutAllViews()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @objc func upvoteAction() {
        vote(.upvote)
    }

    @objc func downvoteAction() {
        vote(.downvote)
    }

    func vote(_ vote: VoteType) {
        VotePost.default.vote(post: post!, vote: vote) { [self] result in
            switch result {
            case let .failure(err):
                MicroAPI.default.errorHandling(error: err, caller: self.contentView)
            case let .success(votepost):
                DispatchQueue.main.async {
                    post?.score = votepost.score
                    post?.vote = votepost.status
                }
            }
        }
    }
}

private extension PostCellView {
    func layoutAllViews() {
        layoutProfilePictureImageView()
        layoutUsernameLabel()
        layoutPostContentTextView()
        layoutPostImageView()
        layoutPostLinkBackgroundView()
        layoutPostLinkLabel()
        layoutUpvoteButton()
        layoutPostScoreLabel()
        layoutDownvoteButton()
        layoutPostDateLabel()
        layoutReplycountIcon()
        layoutReplycountLabel()
        layoutInteractioncountIcon()
        layoutInteractioncountLabel()
    }

    func layoutProfilePictureImageView() {
        profilePictureImageView.snp.removeConstraints()
        profilePictureImageView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.top.equalTo(contentView.snp.top).offset(16)
        }
    }

    func layoutUsernameLabel() {
        usernameLabel.snp.removeConstraints()
        usernameLabel.snp.makeConstraints { make in
            make.leading.equalTo(profilePictureImageView.snp.trailing).offset(12)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            if let tempPost = post, tempPost.author.plus {
                make.centerY.equalTo(profilePictureImageView.snp.centerY).offset(-4)
            } else {
                make.centerY.equalTo(profilePictureImageView.snp.centerY)
            }
            make.height.equalTo(25)
        }
    }

    func layoutPostContentTextView() {
        postContentTextView.snp.removeConstraints()
        postContentTextView.snp.makeConstraints { make in
            make.top.equalTo(profilePictureImageView.snp.bottom).offset(12)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
        }
    }

    func layoutPostImageView(height _: Int? = nil) {
        postImageView.snp.removeConstraints()
        postImageView.snp.makeConstraints { make in
            make.top.equalTo(postContentTextView.snp.bottom).offset(12)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.height.equalTo(postImageView.image != nil ? Int(postImageView.image!.size.height / 3) : 0)
        }
    }

    func layoutPostLinkBackgroundView(hidden: Bool = false, remake _: Bool = false) {
        postLinkBackgroundView.snp.removeConstraints()
        postLinkBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(postImageView.snp.bottom).offset(12)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.height.equalTo(hidden ? 0 : 35)
        }
    }

    func layoutPostLinkLabel() {
        postLinkLabel.snp.removeConstraints()
        postLinkLabel.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.top).offset(8)
            make.leading.equalTo(postLinkBackgroundView.snp.leading).offset(8)
            make.trailing.equalTo(postLinkBackgroundView.snp.trailing).offset(-8)
            make.bottom.equalTo(postLinkBackgroundView.snp.bottom).offset(-8)
        }
    }

    func layoutUpvoteButton() {
        upvoteButton.snp.removeConstraints()
        upvoteButton.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
    }

    func layoutPostScoreLabel() {
        postScoreLabel.snp.removeConstraints()
        postScoreLabel.snp.makeConstraints { make in
            make.centerY.equalTo(upvoteButton.snp.centerY)
            make.leading.equalTo(upvoteButton.snp.trailing).offset(4)
            make.height.equalTo(30)
        }
    }

    func layoutDownvoteButton() {
        downvoteButton.snp.removeConstraints()
        downvoteButton.snp.makeConstraints { make in
            make.centerY.equalTo(upvoteButton.snp.centerY)
            make.leading.equalTo(postScoreLabel.snp.trailing).offset(4)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
    }

    func layoutPostDateLabel() {
        postdateLabel.snp.removeConstraints()
        postdateLabel.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).offset(-16)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(21)
        }
    }

    func layoutReplycountIcon() {
        replycountIcon.snp.removeConstraints()
        replycountIcon.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.trailing.equalTo(postdateLabel.snp.leading).offset(-10)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(21)
            make.width.equalTo(15)
        }
    }

    func layoutReplycountLabel() {
        replycountLabel.snp.removeConstraints()
        replycountLabel.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.trailing.equalTo(replycountIcon.snp.leading).offset(-6)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(21)
        }
    }

    func layoutInteractioncountIcon() {
        interactioncountIcon.snp.removeConstraints()
        interactioncountIcon.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.trailing.equalTo(replycountLabel.snp.leading).offset(-10)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(21)
            make.width.equalTo(15)
        }
    }

    func layoutInteractioncountLabel() {
        interactioncountLabel.snp.removeConstraints()
        interactioncountLabel.snp.makeConstraints { make in
            make.top.equalTo(postLinkBackgroundView.snp.bottom).offset(16)
            make.trailing.equalTo(interactioncountIcon.snp.leading).offset(-6)
            make.bottom.equalTo(contentView.snp.bottom).offset(-16)
            make.height.equalTo(21)
        }
    }
}

extension PostCellView: UITextViewDelegate {
    func textView(_: UITextView, shouldInteractWith url: URL, in _: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            let stringURL = url.absoluteString
            if stringURL.hasPrefix("user:") {
                let selUser = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 5) ..< stringURL.endIndex]
                let spicaUserURL = URL(string: "spica://user/\(selUser)")!
                if UIApplication.shared.canOpenURL(spicaUserURL) {
                    UIApplication.shared.open(spicaUserURL)
                }
            } else if stringURL.hasPrefix("url:") {
                var selURL = stringURL[stringURL.index(stringURL.startIndex, offsetBy: 4) ..< stringURL.endIndex]
                if !selURL.starts(with: "https://"), !selURL.starts(with: "http://") {
                    selURL = "https://" + selURL
                }
                let adaptedURL = URL(string: String(selURL))
                delegate?.clickedLink(adaptedURL!)
            } else if stringURL.isValidURL {
                delegate?.clickedLink(url)
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
        var actions = [UIAction]()

        let copyPostID = UIAction(title: "Copy post ID", image: UIImage(systemName: "doc.on.doc")) { [self] _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = post?.id
            SPAlert.present(title: "Copied", preset: .done)
        }

        actions.append(copyPostID)

        let copyUserID = UIAction(title: "Copy user ID", image: UIImage(systemName: "person.circle")) { [self] _ in
            let pasteboard = UIPasteboard.general
            pasteboard.string = post?.author.id
            SPAlert.present(title: "Copied", preset: .done)
        }

        actions.append(copyUserID)

        let reply = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.left")) { [self] _ in
            self.delegate?.openPostView(.reply, preText: nil, preLink: nil, parentID: post!.id)
        }

        actions.append(reply)

        let repost = UIAction(title: "Repost", image: UIImage(systemName: "arrowshape.turn.up.right")) { [self] _ in
            self.delegate?.openPostView(.post, preText: nil, preLink: "https://micro.alles.cx/p/\(post!.id)", parentID: nil)
        }

        actions.append(repost)

        let bookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")

        let isBookmarked = bookmarks.contains(where: { $0.id == post!.id })

        let bookmark = UIAction(title: isBookmarked ? "Remove Bookmark" : "Add Bookmark", image: isBookmarked ? UIImage(systemName: "bookmark.slash") : UIImage(systemName: "bookmark")) { [self] _ in

            if isBookmarked {
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
                var currentBookmarks = UserDefaults.standard.structArrayData(StoredBookmark.self, forKey: "savedBookmarks")
                currentBookmarks.append(StoredBookmark(id: post!.id, added: Date()))
                UserDefaults.standard.setStructArray(currentBookmarks, forKey: "savedBookmarks")
                SPAlert.present(title: "Added!", preset: .done)
                self.delegate?.reloadData()
            }
        }

        actions.append(bookmark)

        let userID = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

        if post?.author.id == userID! {
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                EZAlertController.alert("Delete post?", message: "Are you sure you want to delete your post? It'll be gone forever (a very long time)", buttons: ["Cancel", "Delete"], buttonsPreferredStyle: [.cancel, .destructive]) { [self] _, index in
                    guard index == 1 else { return }

                    MicroAPI.default.deletePost(post!.id) { result in
                        switch result {
                        case let .failure(err):
                            EZAlertController.alert("Error", message: "The following error occurred:\n\n\(err.error.name)")
                        case .success:
                            DispatchQueue.main.async {
                                SPAlert.present(title: "Deleted", preset: .done)
                                self.delegate?.reloadData()
                            }
                        }
                    }
                }
            }
            actions.append(delete)
        }

        return UIMenu(title: "Post", children: actions)
    }
}

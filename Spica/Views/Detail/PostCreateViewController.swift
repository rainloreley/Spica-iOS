//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 01.07.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Adrian Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import KMPlaceholderTextView
import SnapKit
import SPAlert
import SwiftKeychainWrapper
import SwiftUI
import UIKit

protocol PostCreateDelegate {
    func didSendPost(sentPost: SentPost)
}

class PostCreateViewController: UIViewController, UITextViewDelegate {
    var userPfp: UIImageView!
    var contentTextView: KMPlaceholderTextView!
    var linkTextField: UITextField!

    var type: PostType!
    var parentID: String?
    var imageButton: UIBarButtonItem!

    var selectedImage: UIImage?
    var imagePicker: UIImagePickerController!
    var linkFieldShown: Bool = false

    var delegate: PostCreateDelegate!

    var loadingHud: JGProgressHUD!

    var sendButton: UIBarButtonItem!
    var linkButton: UIBarButtonItem!
    var imagePreview: UIImageView!

    var preText: String!

    var quotes = [
        "\"The greatest glory in living lies not in never falling, but in rising every time we fall.\" -Nelson Mandela",
        "\"The way to get started is to quit talking and begin doing.\" -Walt Disney",
        "\"Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking.\" -Steve Jobs",
        "\"If life were predictable it would cease to be life, and be without flavor.\" -Eleanor Roosevelt",
        "\"If you look at what you have in life, you'll always have more. If you look at what you don't have in life, you'll never have enough.\" -Oprah Winfrey",
    ]

    private var progressBarController = ProgressBarController(progress: 0, color: .gray)

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideKeyboardWhenTappedAround()
        navigationItem.title = type == PostType.post ? SLocale(.POST_NOUN) : SLocale(.REPLY_SINGULAR)
        navigationController?.navigationBar.prefersLargeTitles = false

        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockAllTouches

        imageButton = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(openImagePicker))
        linkButton = UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: self, action: #selector(toggleLinkField))
        sendButton = UIBarButtonItem(image: UIImage(systemName: "paperplane.fill"), style: .plain, target: self, action: #selector(sendPost))

        #if targetEnvironment(macCatalyst)
            navigationItem.rightBarButtonItems = [sendButton, imageButton]
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissView))
        #else
            navigationItem.leftBarButtonItems = [imageButton, linkButton]
            navigationItem.rightBarButtonItem = sendButton
        #endif

        userPfp = UIImageView(frame: .zero)
        userPfp.image = UIImage(systemName: "person.circle")
        userPfp.layer.cornerRadius = 20
        userPfp.contentMode = .scaleAspectFit
        userPfp.clipsToBounds = true
        view.addSubview(userPfp)

        contentTextView = KMPlaceholderTextView(frame: .zero)
        contentTextView.font = .systemFont(ofSize: 18)
        // contentTextView.placeholder = SLocale(.NEWPOST_PLACEHOLDER)
        contentTextView.placeholder = quotes.randomElement() ?? SLocale(.NEWPOST_PLACEHOLDER)
        contentTextView.placeholderColor = UIColor.tertiaryLabel
        contentTextView.delegate = self
        let dropInteraction = UIDropInteraction(delegate: self)
        contentTextView.addInteraction(dropInteraction)
        if preText != nil {
            contentTextView.text = preText
        }

        view.addSubview(contentTextView)

        linkTextField = UITextField(frame: .zero)
        linkTextField.borderStyle = .roundedRect
        linkTextField.placeholder = "https://micro.alles.cx"
        view.addSubview(linkTextField)

        userPfp.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalTo(40)
            make.top.equalTo(view.snp.top).offset(80)
            make.leading.equalTo(view.snp.leading).offset(16)
        }

        linkTextField.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).offset(80)
            make.leading.equalTo(view.snp.leading).offset(72)
            make.trailing.equalTo(view.snp.trailing).offset(-32)
            if linkFieldShown {
                make.bottom.equalTo(contentTextView.snp.top).offset(-16)
                make.height.equalTo(32)
            } else {
                make.bottom.equalTo(contentTextView.snp.top)
                make.height.equalTo(0)
            }
        }

        imagePreview = UIImageView(frame: .zero)
        imagePreview.image = nil
        view.addSubview(imagePreview)

        imagePreview.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leading).offset(72)
            make.trailing.equalTo(view.snp.trailing).offset(-32)
            make.height.equalTo(0)
            make.bottom.equalTo(view.snp.bottom).offset(-16)
        }

        imagePreview.isUserInteractionEnabled = true
        imagePreview.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(openImagePicker)))

        contentTextView.snp.makeConstraints { make in
            // make.top.equalTo(view.snp.top).offset(80)
            make.leading.equalTo(view.snp.leading).offset(72)
            make.trailing.equalTo(view.snp.trailing).offset(-32)
            make.bottom.equalTo(imagePreview.snp.top).offset(-16)
        }

        let progressRingUI = UIHostingController(rootView: CircularProgressBar(controller: progressBarController))
        view.addSubview(progressRingUI.view)

        progressRingUI.view.snp.makeConstraints { make in
            make.width.equalTo(35)
            make.height.equalTo(35)
            make.top.equalTo(userPfp.snp.bottom).offset(32)
            make.leading.equalTo(view.snp.leading).offset(16)
        }

        let calculation = Double(contentTextView.text.count) / Double(500)

        progressBarController.progress = Float(calculation)
    }

    @objc func toggleLinkField() {
        /* linkTextField.snp.remakeConstraints { (make) in
         	make.top.equalTo(view.snp.top).offset(80)
         	make.leading.equalTo(view.snp.leading).offset(72)
         	make.trailing.equalTo(view.snp.trailing).offset(-32)
         	make.bottom.equalTo(contentTextView.snp.top).offset(-16)
         	if linkFieldShown {
         		make.height.equalTo(0)
         		linkFieldShown = false
         	}
         	else {
         		make.height.equalTo(32)
         		linkFieldShown = true
         	}
         } */
        UIView.animate(withDuration: 0.3) { [self] in
            linkTextField.snp.updateConstraints { make in
                if linkFieldShown {
                    make.height.equalTo(0)
                    make.bottom.equalTo(contentTextView.snp.top)
                    linkFieldShown = false
                } else {
                    make.height.equalTo(32)
                    make.bottom.equalTo(contentTextView.snp.top).offset(-16)
                    linkFieldShown = true
                }
            }
            linkTextField.superview?.layoutIfNeeded()
        }
    }

    func resizeImagePreview(image: UIImage?) {
        if image != nil {
            imagePreview.clipsToBounds = true
            imagePreview.contentMode = .scaleAspectFit

            let aspectRatio = image!.size.width / image!.size.height

            var width = image!.size.width
            var dividerCounter = CGFloat(1)
            var height = image!.size.height

            while height > (view.frame.height / 3) {
                height = view.frame.height / dividerCounter
                width = height * aspectRatio
                dividerCounter += 1
            }

            if width - view.frame.width > 1 {
                width = width - (width - view.frame.width) - 32
                height = height - (width - view.frame.width) - 32
            }

            imagePreview.snp.remakeConstraints { make in
                make.centerX.equalTo(view.snp.centerX)
                make.height.equalTo(height)
                make.width.equalTo(width)
                make.bottom.equalTo(view.snp.bottom).offset(-16)
            }
        } else {
            imagePreview.snp.remakeConstraints { make in
                make.leading.equalTo(view.snp.leading).offset(72)
                make.trailing.equalTo(view.snp.trailing).offset(-32)
                make.height.equalTo(0)
                make.bottom.equalTo(view.snp.bottom).offset(-16)
            }
        }
    }

    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    func textViewDidChange(_ textView: UITextView) {
        let calculation = Double(textView.text.count) / Double(500)

        progressBarController.progress = Float(calculation)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return newText.count < 501
    }

    @objc func openImagePicker(sender _: Any?) {
        if selectedImage != nil {
            EZAlertController.actionSheet(SLocale(.IMAGE), message: "", sourceView: view, actions: [
                UIAlertAction(title: SLocale(.SELECT_ANOTHER_IMAGE), style: .default, handler: { _ in
                    self.present(self.imagePicker, animated: true)
				}), UIAlertAction(title: SLocale(.REMOVE), style: .destructive, handler: { _ in
                    self.selectedImage = nil
                    self.imageButton.image = UIImage(systemName: "photo")
                    self.imagePreview.image = nil
                    self.resizeImagePreview(image: nil)
				}), UIAlertAction(title: SLocale(.CANCEL), style: .cancel, handler: nil),
            ])
        } else {
            present(imagePicker, animated: true)
        }
    }

    override func viewDidAppear(_: Bool) {
        DispatchQueue.global(qos: .utility).async {
            let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")

            let pfpImage = ImageLoader.loadImageFromInternet(url: (URL(string: "https://avatar.alles.cc/\(id!)") ?? URL(string: "https://avatar.alles.cc/_"))!)

            DispatchQueue.main.async {
                self.userPfp.image = pfpImage
            }
        }
    }

    @objc func sendPost() {
        loadingHud.show(in: view)
        sendButton.isEnabled = false
        contentTextView.layer.cornerRadius = 0
        contentTextView.layer.borderWidth = 0
        linkTextField.borderStyle = .roundedRect
        contentTextView.layer.borderColor = UIColor.clear.cgColor
        if linkFieldShown, !linkTextField.text!.isValidURL {
            linkTextField.layer.borderWidth = 1
            linkTextField.layer.borderColor = UIColor.systemRed.cgColor
            loadingHud.dismiss()
            sendButton.isEnabled = true
            return
        }
        if contentTextView.text.isEmpty {
            contentTextView.layer.cornerRadius = 12
            contentTextView.layer.borderWidth = 1
            contentTextView.layer.borderColor = UIColor.systemRed.cgColor
            loadingHud.dismiss()
            sendButton.isEnabled = true
            return
        } else {
            // AllesAPI.default.sendPost(newPost: NewPost(content: contentTextView.text, image: selectedImage, type: type, parent: parentID))
            AllesAPI.default.sendPost(content: contentTextView.text, image: selectedImage, parent: parentID, url: linkTextField.text)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        self.loadingHud.dismiss()
                        self.sendButton.isEnabled = true

                        AllesAPI.default.errorHandling(error: err, caller: self.view)

                    default: break
                    }
                } receiveValue: { [unowned self] in
                    self.loadingHud.dismiss()
                    self.sendButton.isEnabled = true
                    self.delegate.didSendPost(sentPost: $0)
                    self.dismiss(animated: true)
                    SPAlert.present(title: SLocale(.POST_SENT), preset: .done)
                }
                .store(in: &subscriptions)
        }
    }
}

extension PostCreateViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = pickedImage
            imageButton.image = UIImage(systemName: "photo.fill")
            imagePreview.image = pickedImage
            resizeImagePreview(image: pickedImage)
        }

        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true)
    }
}

enum PostType {
    case post
    case reply
}

extension PostCreateViewController: UIDropInteractionDelegate {
    func dropInteraction(_: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(_: UIDropInteraction, sessionDidUpdate _: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: UIImage.self) { imageItems in
            let images = imageItems as! [UIImage]
            self.selectedImage = images.first
            self.imageButton.image = UIImage(systemName: "photo.fill")
            self.imagePreview.image = images.first
            self.resizeImagePreview(image: images.first)
        }
    }
}

//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 09.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import JGProgressHUD
import Kingfisher
import KMPlaceholderTextView
import SPAlert
import SwiftKeychainWrapper
import SwiftUI
import UIKit

protocol CreatePostDelegate {
    func didSendPost(post: Post)
}

class CreatePostViewController: UIViewController, UITextViewDelegate {
    var userPfp: UIImageView!
    var contentTextView: KMPlaceholderTextView!
    var linkTextField: UITextField!

    var type: PostType!
    var parentID: String?
    var imageButton: UIBarButtonItem!

    var selectedImage: UIImage?
    var imagePicker: UIImagePickerController!
    var linkFieldShown: Bool = false

    var delegate: CreatePostDelegate!

    var loadingHud: JGProgressHUD!

    var sendButton: UIBarButtonItem!
    var linkButton: UIBarButtonItem!
    var imagePreview: UIImageView!

    var preText: String!

    private var progressBarController = ProgressBarController(progress: 0, color: .gray)

    private var subscriptions = Set<AnyCancellable>()

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideKeyboardWhenTappedAround()
        navigationItem.title = type == PostType.post ? "Post" : "Reply"
        navigationController?.navigationBar.prefersLargeTitles = false

        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.delegate = self

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = "Loading..."
        loadingHud.interactionType = .blockAllTouches

        imageButton = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(openImagePicker))
        linkButton = UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: self, action: #selector(toggleLinkField))
        sendButton = UIBarButtonItem(image: UIImage(systemName: "paperplane.fill"), style: .plain, target: self, action: #selector(sendPost))

        #if targetEnvironment(macCatalyst)
            navigationItem.rightBarButtonItems = [sendButton, imageButton, linkButton]
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

        contentTextView.placeholder = "Hi! What's up?"
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
        linkTextField.autocapitalizationType = .none
        linkTextField.placeholder = "https://micro.alles.cx"
        linkTextField.autocorrectionType = .no
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
            EZAlertController.actionSheet("Image options", message: "", sourceView: view, actions: [
                UIAlertAction(title: "Select another image", style: .default, handler: { _ in
                    self.present(self.imagePicker, animated: true)
					}), UIAlertAction(title: "Remove image", style: .destructive, handler: { _ in
                    self.selectedImage = nil
                    self.imageButton.image = UIImage(systemName: "photo")
                    self.imagePreview.image = nil
                    self.resizeImagePreview(image: nil)
					}), UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
            ])
        } else {
            present(imagePicker, animated: true)
        }
    }

    override func viewDidAppear(_: Bool) {
        let id = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id")
        userPfp.kf.setImage(with: URL(string: "https://avatar.alles.cc/\(id!)"))
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
            MicroAPI.default.sendPost(content: contentTextView.text, image: selectedImage, parent: parentID, url: linkTextField.text)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        self.loadingHud.dismiss()
                        self.sendButton.isEnabled = true

                        MicroAPI.default.errorHandling(error: err, caller: self.view)

                    default: break
                    }
                } receiveValue: { [unowned self] in
                    self.loadingHud.dismiss()
                    self.sendButton.isEnabled = true
                    self.delegate.didSendPost(post: $0)
                    self.dismiss(animated: true)
                    SPAlert.present(title: "Post sent!", preset: .done)
                }
                .store(in: &subscriptions)
        }
    }
}

extension CreatePostViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
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

extension CreatePostViewController: UIDropInteractionDelegate {
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

enum PostType {
    case post
    case reply
}

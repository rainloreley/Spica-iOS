//
//  PostCreateViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
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
    // var sendButton: UIButton!
    var userPfp: UIImageView!
    var contentTextView: KMPlaceholderTextView!
    var type: PostType!
    var parentID: String?
    var imageButton: UIBarButtonItem!

    var selectedImage: UIImage?
    var imagePicker: UIImagePickerController!

    var delegate: PostCreateDelegate!

    var loadingHud: JGProgressHUD!

    var sendButton: UIBarButtonItem!

    private var progressBarController = ProgressBarController(progress: 0, color: .gray)

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
        loadingHud.textLabel.text = "Loading"
        loadingHud.interactionType = .blockAllTouches

        imageButton = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(openImagePicker))

        sendButton = UIBarButtonItem(image: UIImage(systemName: "paperplane.fill"), style: .plain, target: self, action: #selector(sendPost))

        navigationItem.leftBarButtonItem = imageButton
        navigationItem.rightBarButtonItem = sendButton

        /* sendButton = UIButton(type: .system)
         sendButton.setTitle(type == PostType.post ? "Post" : "Reply", for: .normal)
         sendButton.setTitleColor(.white, for: .normal)
         sendButton.backgroundColor = UIColor(named: "PostButtonColor")
         sendButton.layer.cornerRadius = 12
         sendButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
         sendButton.addTarget(self, action: #selector(sendPost), for: .touchUpInside)
         view.addSubview(sendButton) */

        /* imageButton = UIButton(type: .system)
         imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
         imageButton.addTarget(self, action: #selector(self.openImagePicker), for: .touchUpInside)
         view.addSubview(imageButton) */

        userPfp = UIImageView(frame: .zero)
        userPfp.image = UIImage(systemName: "person.circle")
        userPfp.layer.cornerRadius = 20
        userPfp.contentMode = .scaleAspectFit
        userPfp.clipsToBounds = true
        view.addSubview(userPfp)

        contentTextView = KMPlaceholderTextView(frame: .zero)
        contentTextView.font = .systemFont(ofSize: 18)
        contentTextView.placeholder = "What's on your mind?"
        contentTextView.placeholderColor = UIColor.tertiaryLabel
        contentTextView.delegate = self

        view.addSubview(contentTextView)

        /* sendButton.snp.makeConstraints { make in
             make.bottom.equalTo(view.snp.bottom).offset(-50)
             make.centerX.equalTo(view.snp.centerX)
             make.height.equalTo(50)
             make.width.equalTo(view.snp.width).offset(-32)
         } */

        userPfp.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalTo(40)
            make.top.equalTo(view.snp.top).offset(80)
            make.left.equalTo(view.snp.left).offset(16)
        }

        /* imageButton.snp.makeConstraints { (make) in
         	make.height.equalTo(40)
         	make.width.equalTo(40)
         	make.bottom.equalTo(view.snp.bottom).offset(-80)
         	make.left.equalTo(view.snp.left).offset(16)
         } */

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).offset(80)
            make.left.equalTo(view.snp.left).offset(72)
            make.right.equalTo(view.snp.right).offset(-32)
            make.bottom.equalTo(view.snp.bottom).offset(-16)
        }

        // progressRing = CircularProgressView()
        let progressRingUI = UIHostingController(rootView: CircularProgressBar(controller: progressBarController))
        view.addSubview(progressRingUI.view)

        progressRingUI.view.snp.makeConstraints { make in
            make.width.equalTo(35)
            make.height.equalTo(35)
            make.top.equalTo(userPfp.snp.bottom).offset(32)
            make.left.equalTo(view.snp.left).offset(16)
        }

        // Do any additional setup after loading the view.
    }

    func textViewDidChange(_ textView: UITextView) { // Handle the text changes here
        let calculation = Double(textView.text.count) / Double(500)

        progressBarController.progress = Float(calculation)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        return newText.count < 501
    }

    @objc func openImagePicker(sender _: UIBarButtonItem) {
        if selectedImage != nil {
            EZAlertController.actionSheet("Image", message: "Select an action", sourceView: view, actions: [
                UIAlertAction(title: "Select another image", style: .default, handler: { _ in
                    // self.imagePicker.present(from: self.view)
                    self.present(self.imagePicker, animated: true, completion: nil)
			}), UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                    self.selectedImage = nil
                    self.imageButton.image = UIImage(systemName: "photo")
			}), UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
            ])
        } else {
            present(imagePicker, animated: true, completion: nil)
        }
    }

    override func viewDidAppear(_: Bool) {
        let userUsername = KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.username")

        let pfpImage = ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/\(userUsername!)")!)

        userPfp.image = pfpImage
    }

    @objc func sendPost() {
        loadingHud.show(in: view)
        sendButton.isEnabled = false
        contentTextView.layer.cornerRadius = 0
        contentTextView.layer.borderWidth = 0
        contentTextView.layer.borderColor = UIColor.clear.cgColor
        if contentTextView.text.isEmpty {
            contentTextView.layer.cornerRadius = 12
            contentTextView.layer.borderWidth = 1
            contentTextView.layer.borderColor = UIColor.systemRed.cgColor
            loadingHud.dismiss()
            sendButton.isEnabled = true
            return
        } else {
            AllesAPI.default.sendPost(newPost: NewPost(content: contentTextView.text, image: selectedImage, type: type, parent: parentID)) { result in
                switch result {
                case let .success(sentPost):

                    DispatchQueue.main.async {
                        self.loadingHud.dismiss()
                        self.sendButton.isEnabled = true
                        self.delegate.didSendPost(sentPost: sentPost)
                        self.dismiss(animated: true, completion: nil)
                        SPAlert.present(title: "Post sent!", preset: .done)
                    }
                case let .failure(apiError):
                    DispatchQueue.main.async {
                        self.loadingHud.dismiss()
                        self.sendButton.isEnabled = true

                        EZAlertController.alert("Error", message: apiError.message, buttons: ["Ok"]) { _, _ in
                            if apiError.action != nil, apiError.actionParameter != nil {
                                if apiError.action == AllesAPIErrorAction.navigate {
                                    if apiError.actionParameter == "login" {
                                        let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                        mySceneDelegate.window?.makeKeyAndVisible()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

extension PostCreateViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = pickedImage
            imageButton.image = UIImage(systemName: "photo.fill")
        }

        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

enum PostType {
    case post
    case reply
}

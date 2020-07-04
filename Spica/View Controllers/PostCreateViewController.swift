//
//  PostCreateViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 01.07.20.
//

import KMPlaceholderTextView
import SnapKit
import UIKit

protocol PostCreateDelegate {
    func didSendPost(sentPost: SentPost)
}

class PostCreateViewController: UIViewController {
    var sendButton: UIButton!
    var userPfp: UIImageView!
    var contentTextView: KMPlaceholderTextView!
    var type: PostType!
    var parentID: String?

    var delegate: PostCreateDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideKeyboardWhenTappedAround()
        navigationItem.title = type == PostType.post ? "Post" : "Reply"
        navigationController?.navigationBar.prefersLargeTitles = false

        sendButton = UIButton(type: .system)
        sendButton.setTitle(type == PostType.post ? "Post" : "Reply", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = UIColor(named: "PostButtonColor")
        sendButton.layer.cornerRadius = 12
        sendButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        sendButton.addTarget(self, action: #selector(sendPost), for: .touchUpInside)
        view.addSubview(sendButton)

        let pfpImage = ImageLoader.default.loadImageFromInternet(url: URL(string: "https://avatar.alles.cx/u/adrian")!)
        userPfp = UIImageView(frame: .zero)
        userPfp.image = pfpImage
        userPfp.layer.cornerRadius = 20
        userPfp.contentMode = .scaleAspectFit
        userPfp.clipsToBounds = true
        view.addSubview(userPfp)

        contentTextView = KMPlaceholderTextView(frame: .zero)
        contentTextView.font = .systemFont(ofSize: 18)
        contentTextView.placeholder = "What's on your mind?"

        view.addSubview(contentTextView)

        sendButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottom).offset(-50)
            make.centerX.equalTo(view.snp.centerX)
            make.height.equalTo(50)
            make.width.equalTo(view.snp.width).offset(-32)
        }

        userPfp.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.equalTo(40)
            make.top.equalTo(view.snp.top).offset(80)
            make.left.equalTo(view.snp.left).offset(16)
        }

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).offset(80)
            make.left.equalTo(view.snp.left).offset(72)
            make.right.equalTo(view.snp.right).offset(-32)
            make.bottom.equalTo(sendButton.snp.top).offset(-16)
        }

        // Do any additional setup after loading the view.
    }

    @objc func sendPost() {
        contentTextView.layer.cornerRadius = 0
        contentTextView.layer.borderWidth = 0
        contentTextView.layer.borderColor = UIColor.clear.cgColor
        if contentTextView.text.isEmpty {
            contentTextView.layer.cornerRadius = 12
            contentTextView.layer.borderWidth = 1
            contentTextView.layer.borderColor = UIColor.systemRed.cgColor
            return
        } else {
            AllesAPI.default.sendPost(newPost: NewPost(content: contentTextView.text, image: nil, type: type, parent: parentID)) { result in
                switch result {
                case let .success(sentPost):

                    DispatchQueue.main.async {
                        self.delegate.didSendPost(sentPost: sentPost)
                        self.dismiss(animated: true, completion: nil)
                    }
                case let .failure(apiError):
                    DispatchQueue.main.async {
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

enum PostType {
    case post
    case reply
}

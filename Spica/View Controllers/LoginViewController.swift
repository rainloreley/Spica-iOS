//
//  LoginViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 02.07.20.
//

import Combine
import JGProgressHUD
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    var usernameLabel: UILabel!
    var passwordLabel: UILabel!
    var usernameField: UITextField!
    var passwordField: UITextField!
    var signInButton: UIButton!
    var toolbarDelegate = ToolbarDelegate()

    var createAccountButton: UIButton!

    var loadingHud: JGProgressHUD!

    var legalDisclaimer: UILabel!
    var spicaPrivacy: UIButton!
    var allesPrivacy: UIButton!
    var allesTerms: UIButton!

    private var subscriptions = Set<AnyCancellable>()

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        hideKeyboardWhenTappedAround()

        navigationItem.title = SLocale(.ALLES_LOGIN)
        navigationController?.navigationBar.prefersLargeTitles = true

        usernameField = UITextField(frame: .zero)
        usernameField.borderStyle = .roundedRect
        usernameField.placeholder = "jessica"
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        view.addSubview(usernameField)

        loadingHud = JGProgressHUD(style: .dark)
        loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockAllTouches

        usernameField.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.centerY.equalTo(view.snp.centerY).offset(-90)
            make.width.equalTo(view.snp.width).offset(-64)
            make.height.equalTo(40)
        }

        usernameLabel = UILabel(frame: .zero)
        usernameLabel.text = "\(SLocale(.USERNAME)):"
        view.addSubview(usernameLabel)

        usernameLabel.snp.makeConstraints { make in
            make.bottom.equalTo(usernameField.snp.top).offset(-8)
            make.leading.equalTo(32)
        }

        passwordLabel = UILabel(frame: .zero)
        passwordLabel.text = "\(SLocale(.PASSWORD)):"
        view.addSubview(passwordLabel)

        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(16)
            make.leading.equalTo(32)
        }

        passwordField = UITextField(frame: .zero)
        passwordField.borderStyle = .roundedRect
        passwordField.placeholder = "••••••"
        passwordField.isSecureTextEntry = true
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        view.addSubview(passwordField)

        passwordField.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(passwordLabel.snp.bottom).offset(8)
            make.width.equalTo(view.snp.width).offset(-64)
            make.height.equalTo(40)
        }

        usernameField.delegate = self
        passwordField.delegate = self

        signInButton = UIButton(type: .system)
        signInButton.backgroundColor = UIColor(named: "PostButtonColor")
        signInButton.setTitle(SLocale(.SIGN_IN), for: .normal)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.cornerRadius = 12
        signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        signInButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        view.addSubview(signInButton)

        signInButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(passwordField.snp.bottom).offset(32)
            make.width.equalTo(150)
            make.height.equalTo(40)
        }

        createAccountButton = UIButton(type: .system)
        createAccountButton.setTitle(SLocale(.NO_ACCOUNT), for: .normal)
        createAccountButton.addTarget(self, action: #selector(openCreateAccount), for: .touchUpInside)
        view.addSubview(createAccountButton)

        createAccountButton.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.width.equalTo(200)
            make.height.equalTo(40)
            make.top.equalTo(signInButton.snp.bottom).offset(32)
        }

        legalDisclaimer = UILabel(frame: .zero)
        legalDisclaimer.text = SLocale(.LOGIN_SCREEN_AGREEMENT)
        legalDisclaimer.numberOfLines = 0
        legalDisclaimer.textColor = .secondaryLabel
        legalDisclaimer.font = .systemFont(ofSize: 11)
        view.addSubview(legalDisclaimer)

        legalDisclaimer.snp.makeConstraints { make in
            make.top.equalTo(createAccountButton.snp.bottom).offset(8)
            make.leading.equalTo(view.snp.leading).offset(16)
            make.centerX.equalTo(view.snp.centerX)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
        }

        spicaPrivacy = UIButton(type: .system)
        spicaPrivacy.setTitle("Spica: \(SLocale(.PRIVACY_POLICY))", for: .normal)
        spicaPrivacy.addTarget(self, action: #selector(openLink(_:)), for: .touchUpInside)
        spicaPrivacy.tag = 0
        view.addSubview(spicaPrivacy)

        allesPrivacy = UIButton(type: .system)
        allesPrivacy.setTitle("Alles: \(SLocale(.PRIVACY_POLICY))", for: .normal)
        allesPrivacy.addTarget(self, action: #selector(openLink(_:)), for: .touchUpInside)
        allesPrivacy.tag = 1
        view.addSubview(allesPrivacy)

        allesTerms = UIButton(type: .system)
        allesTerms.setTitle("Alles: \(SLocale(.TERMS_OF_SERVICE))", for: .normal)
        allesTerms.addTarget(self, action: #selector(openLink(_:)), for: .touchUpInside)
        allesTerms.tag = 2
        view.addSubview(allesTerms)

        spicaPrivacy.snp.makeConstraints { make in
            make.top.equalTo(legalDisclaimer.snp.bottom).offset(8)
            make.leading.equalTo(view.snp.leading).offset(16)
        }

        allesPrivacy.snp.makeConstraints { make in
            make.top.equalTo(spicaPrivacy.snp.bottom).offset(8)
            make.leading.equalTo(view.snp.leading).offset(16)
        }

        allesTerms.snp.makeConstraints { make in
            make.top.equalTo(allesPrivacy.snp.bottom).offset(8)
            make.leading.equalTo(view.snp.leading).offset(16)
        }
    }

    @objc func openLink(_ sender: UIButton) {
        var url = ""
        switch sender.tag {
        case 0:
            url = "https://spica.li/privacy"
        case 1:
            url = "https://alles.cx/docs/privacy"
        case 2:
            url = "https://alles.cx/docs/terms"
        default: break
        }

        if UIApplication.shared.canOpenURL(URL(string: url)!) {
            UIApplication.shared.open(URL(string: url)!)
        }
    }

    override func viewDidAppear(_: Bool) {
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "other")
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = nil
            }

            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.setToolbarHidden(false, animated: false)
        #endif
    }

    @objc func openCreateAccount() {
        UIApplication.shared.open(URL(string: "https://alles.cx/register")!)
    }

    @objc func signIn() {
        loadingHud.show(in: view)
        usernameField.layer.borderColor = UIColor.clear.cgColor
        usernameField.layer.borderWidth = 0.0

        passwordField.layer.borderColor = UIColor.clear.cgColor
        passwordField.layer.borderWidth = 0.0

        if !usernameField.text!.isEmpty && !passwordField.text!.isEmpty {
            AllesAPI.default.signInUser(username: usernameField.text!, password: passwordField.text!)
                .receive(on: RunLoop.main)
                .sink {
                    switch $0 {
                    case let .failure(err):
                        DispatchQueue.main.async {
                            self.loadingHud.dismiss()

                            AllesAPI.default.errorHandling(error: err, caller: self.view)
                        }
                    default: break
                    }
                } receiveValue: { _ in
                    DispatchQueue.main.async {
                        let sceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate

                        let initialView = sceneDelegate.setupInitialView()
                        sceneDelegate.window?.rootViewController = initialView

                        self.loadingHud.dismiss()
                        sceneDelegate.window?.makeKeyAndVisible()
                    }
                }.store(in: &subscriptions)
        } else {
            loadingHud.dismiss()
            if usernameField.text!.isEmpty {
                usernameField.layer.borderColor = UIColor.systemRed.cgColor
                usernameField.layer.borderWidth = 1.0
            }
            if passwordField.text!.isEmpty {
                passwordField.layer.borderColor = UIColor.systemRed.cgColor
                passwordField.layer.borderWidth = 1.0
            }
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

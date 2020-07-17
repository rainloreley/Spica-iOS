//
//  UserEditViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 16.07.20.
//

import Combine
import JGProgressHUD
import SPAlert
import UIKit

protocol UserEditDelegate {
    func didSaveUser(user: UpdateUser)
}

class UserEditViewController: UIViewController {
    var delegate: UserEditDelegate!

    var loadingHud: JGProgressHUD!

    var tableView: UITableView!
    var user: User! {
        didSet {
            editableUser = UpdateUser(about: user.about, name: user.displayName, nickname: user.nickname)
        }
    }

    var editableUser: UpdateUser!

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        hero.isEnabled = true

        loadingHud = JGProgressHUD(style: .dark)
		loadingHud.textLabel.text = SLocale(.LOADING_ACTION)
        loadingHud.interactionType = .blockNoTouches

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up.on.square"), style: .plain, target: self, action: #selector(saveData))

        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserEditHeaderCell.self, forCellReuseIdentifier: "userHeader")
        tableView.register(EditTextFieldCell.self, forCellReuseIdentifier: "editTextField")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.equalTo(view.snp.leading)
            make.bottom.equalTo(view.snp.bottom)
            make.trailing.equalTo(view.snp.trailing)
        }

        /* NotificationCenter.default.addObserver(self, selector: #selector(UserEditViewController.keyboardWillShow), name: NSNotification.Name.UIResponder.keyboardWillShowNotification, object: nil)

         NotificationCenter.default.addObserver(self, selector: #selector(UserEditViewController.keyboardWillHide), name: NSNotification.Name.UIResponder.keyboardWillHideNotification, object: nil) */

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_: Bool) {
		navigationItem.title = SLocale(.EDIT_PROFILE)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    @objc func saveData() {
        loadingHud.show(in: view)
        AllesAPI.default.updateProfile(newData: editableUser)
            .receive(on: RunLoop.main)
            .sink {
                switch $0 {
                case let .failure(err):
                    DispatchQueue.main.async {
                        EZAlertController.alert("Error", message: err.message, buttons: ["Ok"]) { _, _ in
                            self.loadingHud.dismiss()
                            if err.action != nil, err.actionParameter != nil {
                                if err.action == AllesAPIErrorAction.navigate {
                                    if err.actionParameter == "login" {
                                        let mySceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
                                        mySceneDelegate.window?.rootViewController = UINavigationController(rootViewController: LoginViewController())
                                        mySceneDelegate.window?.makeKeyAndVisible()
                                    }
                                }
                            }
                        }
                    }
                default: break
                }
            } receiveValue: { [unowned self] in
                navigationController?.popViewController(animated: true)
				SPAlert.present(title: SLocale(.SAVED_ACTION), preset: .done)
                delegate.didSaveUser(user: $0)
            }
            .store(in: &subscriptions)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + 32, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification _: NSNotification) {
        tableView.contentInset = .zero
    }

    /*@objc func keyboardWillShow(_ notification:Notification) {

     	if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
     		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
     	}
     }
     @objc func keyboardWillHide(_ notification:Notification) {

     	if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
     		tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
     	}
     }*/

    override func viewDidAppear(_: Bool) {
        tableView.reloadData()
    }
}

extension UserEditViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return EditHeaders.allCases.count
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
        /* switch section {
         	case 0: return 1
         	case 1: return 1
         	default: return 0
         } */
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        EditHeaders(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if EditHeaders(rawValue: indexPath.section) == .user {
            let cell = tableView.dequeueReusableCell(withIdentifier: "userHeader", for: indexPath) as! UserEditHeaderCell
            cell.selectionStyle = .none
            cell.user = user
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editTextField", for: indexPath) as! EditTextFieldCell
            // cell.user = user

            // cell.placeholder = EditHeaders.init(rawValue: indexPath.section)?.title

            cell.textChanged { [weak tableView] _ in
                switch EditHeaders(rawValue: indexPath.section) {
                case .user: return
                case .name: self.editableUser.name = cell.textField.text!
                    print("TEXTI: \(self.editableUser.name)")
                case .nickname: self.editableUser.nickname = cell.textField.text!
                case .about: self.editableUser.about = cell.textField.text!
                case .none:
                    return
                }
            }

            cell.textField.placeholder = EditHeaders(rawValue: indexPath.section)?.title

            var preValue: String {
                switch EditHeaders(rawValue: indexPath.section) {
                case .user: return ""
                case .name: return editableUser.name
                case .nickname: return editableUser.nickname
                case .about: return editableUser.about
                default: return ""
                }
            }

            cell.textField.text = preValue
            return cell
        }
    }

    enum EditHeaders: Int, CaseIterable {
        case user = 0
        case name = 1
        case nickname = 2
        case about = 3

        var title: String {
            switch self {
            case .user: return ""
				case .name: return SLocale(.NAME)
				case .nickname: return SLocale(.NICKNAME)
				case .about: return SLocale(.ABOUT)
            default: return ""
            }
        }
    }
}

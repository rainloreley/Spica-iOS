//
//  UserEditViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 16.07.20.
//

import Cache
import Combine
import JGProgressHUD
import SPAlert
import UIKit
import Hero

protocol UserEditDelegate {
    func didSaveUser(user: UpdateUser)
}

class UserEditViewController: UIViewController {
    var delegate: UserEditDelegate!

    var loadingHud: JGProgressHUD!
    var toolbarDelegate = ToolbarDelegate()
    private var saveAccountSubscriber: AnyCancellable?
    private var navigateBackSubscriber: AnyCancellable?

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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: SLocale(.SAVE_ACTION), style: .plain, target: self, action: #selector(saveData))

        #if targetEnvironment(macCatalyst)
            tableView = UITableView(frame: view.bounds, style: .plain)
        #else
            tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        #endif
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

    override func viewWillDisappear(_: Bool) {
        saveAccountSubscriber?.cancel()
        navigateBackSubscriber?.cancel()
    }

    override func viewWillAppear(_: Bool) {
        navigationItem.title = SLocale(.EDIT_PROFILE)
        navigationController?.navigationBar.prefersLargeTitles = false

        let notificationCenter = NotificationCenter.default

        saveAccountSubscriber = notificationCenter.publisher(for: .saveProfile)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.saveData()
			})

        navigateBackSubscriber = notificationCenter.publisher(for: .navigateBack)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.navigateBack()
			})
    }

    @objc func navigateBack() {
        if (navigationController?.viewControllers.count)! > 1 {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func saveData() {
        loadingHud.show(in: view)
        AllesAPI.default.updateProfile(newData: editableUser)
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
        #if targetEnvironment(macCatalyst)

            let toolbar = NSToolbar(identifier: "editUserProfile")
            toolbarDelegate.navStack = (navigationController?.viewControllers)!
            toolbar.delegate = toolbarDelegate
            toolbar.displayMode = .iconOnly

            if let titlebar = view.window!.windowScene!.titlebar {
                titlebar.toolbar = toolbar
                titlebar.toolbarStyle = .automatic
            }

            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setToolbarHidden(true, animated: false)
        #endif

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

            cell.textChanged { _ in
                switch EditHeaders(rawValue: indexPath.section) {
                case .user: return
                case .name: self.editableUser.name = cell.textField.text!
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
                // default: return ""
            }
        }
    }
}

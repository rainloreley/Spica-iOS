//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 23.10.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Combine
import SPAlert
import SwiftUI
import UIKit

class UpdateStatusViewController: UIAlertController {
    var mainView: UIView!
    var heightConstraint: NSLayoutConstraint?
    var statusController = UpdateStatusController()
    var rootViewHeight: CGFloat! {
        didSet {
            if heightConstraint != nil {
                view.removeConstraint(heightConstraint!)
            }

            heightConstraint = NSLayoutConstraint(item: view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: rootViewHeight)

            view.addConstraint(heightConstraint!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let exitBtn: UIButton! = {
            let btn = UIButton(type: .close)
            btn.tintColor = .gray
            btn.addTarget(self, action: #selector(closeView), for: .touchUpInside)
            return btn
        }()

        view.addSubview(exitBtn)
        exitBtn.snp.makeConstraints { make in
            make.top.equalTo(16)
			if #available(iOS 14.0, *) {
				make.trailing.equalTo(view.snp.trailing).offset(-16)
			}
			else {
				make.trailing.equalTo(view.snp.trailing).offset(-32)
			}
            make.height.equalTo(30)
            make.width.equalTo(30)
        }

        statusController.delegate = self

        mainView = UIHostingController(rootView: UpdateStatusView(controller: statusController)).view
        mainView.backgroundColor = .clear
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(exitBtn.snp.bottom).offset(16)
            make.leading.equalTo(view.snp.leading).offset(32)
            make.trailing.equalTo(view.snp.trailing).offset(-32)
            make.bottom.equalTo(view.snp.bottom).offset(-32)
        }

        // Do any additional setup after loading the view.
    }

    @objc func closeView() {
        dismiss(animated: true, completion: nil)
    }
}

extension UpdateStatusViewController: UpdateStatusDelegate {
    func statusUpdated() {
        DispatchQueue.main.async {
            SPAlert.present(title: "Status set!", preset: .done)
            self.dismiss(animated: true, completion: nil)
        }
    }

    func statusError(err: MicroError) {
        DispatchQueue.main.async {
            MicroAPI.default.errorHandling(error: err, caller: self.view)
        }
    }
}

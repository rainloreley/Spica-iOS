//
//  GlobalSplitViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 15.07.20.
//

import UIKit

@available(iOS 14.0, *)
class GlobalSplitViewController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override init(style: UISplitViewController.Style) {
        super.init(style: style)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

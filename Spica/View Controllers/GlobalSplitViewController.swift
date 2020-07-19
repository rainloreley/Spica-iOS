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

        // Do any additional setup after loading the view.
    }

    override init(style: UISplitViewController.Style) {
        super.init(style: style)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

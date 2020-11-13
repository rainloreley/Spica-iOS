//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 27.10.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Lightbox
import UIKit

class ImageDetailViewController: LightboxController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let shareBtn: UIButton = {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
            btn.addTarget(self, action: #selector(shareImage(_:)), for: .touchUpInside)
            btn.tintColor = .white
			if #available(iOS 13.4, *) {
				btn.isPointerInteractionEnabled = true
			}
            return btn
        }()

        headerView.addSubview(shareBtn)
        shareBtn.snp.makeConstraints { make in
            make.centerY.equalTo(headerView.closeButton.snp.centerY)
            make.leading.equalTo(headerView.snp.leading).offset(8)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
		
		if #available(iOS 13.4, *) {
			headerView.closeButton.isPointerInteractionEnabled = true
		}
    }

    @objc func shareImage(_ sender: UIButton) {
        if let image = images.first?.image {
            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
            }
            present(activityViewController, animated: true, completion: nil)
        }
    }
}

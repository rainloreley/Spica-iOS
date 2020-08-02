//
//  NewPrivacyPolicyViewController.swift
//  Spica
//
//  Created by Adrian Baumgart on 02.08.20.
//

import UIKit
import Down

class NewPrivacyPolicyViewController: UIViewController {
	
	var introductionLabel: UILabel!

	var markdownView: TextView!
	
	var acceptButton: UIButton!
	
	var privacyPolicy: PrivacyPolicy?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .systemBackground
		navigationItem.title = SLocale(.PRIVACY_POLICY)
		
		introductionLabel = UILabel(frame: .zero)
		introductionLabel.text = "We updated our Privacy Policy. Please read it carefully. If you don't agree, please stop using the app."
		introductionLabel.numberOfLines = 0
		view.addSubview(introductionLabel)
		
		introductionLabel.snp.makeConstraints { (make) in
			make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
			make.leading.equalTo(view.snp.leading).offset(8)
			make.trailing.equalTo(view.snp.trailing).offset(-8)
			//make.height.equalTo(40)
		}
		
		acceptButton = UIButton(type: .system)
		acceptButton.setTitle("Agree and continue", for: .normal)
		acceptButton.setTitleColor(.white, for: .normal)
		acceptButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
		acceptButton.backgroundColor = .systemBlue
		acceptButton.layer.cornerRadius = 12
		acceptButton.addTarget(self, action: #selector(acceptAndContinue), for: .touchUpInside)
		view.addSubview(acceptButton)
		
		acceptButton.snp.makeConstraints { (make) in
			make.bottom.equalTo(view.snp.bottom).offset(-8)
			make.leading.equalTo(view.snp.leading).offset(8)
			make.trailing.equalTo(view.snp.trailing).offset(-8)
			make.height.equalTo(40)
		}
		
		markdownView = UITextView(frame: .zero)
		view.addSubview(markdownView!)
		
		markdownView?.snp.makeConstraints({ (make) in
			make.top.equalTo(introductionLabel.snp.bottom).offset(16)
			make.leading.equalTo(view.snp.leading)
			make.trailing.equalTo(view.snp.trailing)
			make.bottom.equalTo(acceptButton.snp.top).offset(-8)
		})
		

        // Do any additional setup after loading the view.
    }
	
	@objc func acceptAndContinue() {
		UserDefaults.standard.set(true, forKey: "spica_privacy_\(privacyPolicy!.updated)")
		dismiss(animated: true, completion: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		//markdownView = try? DownView(frame: .zero, markdownString: (privacyPolicy!.markdown))
		markdownView.attributedText = try? Down(markdownString: privacyPolicy!.markdown).toAttributedString()
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

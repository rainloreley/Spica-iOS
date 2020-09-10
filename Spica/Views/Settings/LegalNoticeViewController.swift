//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 10.09.20.
//
// Licensed under the GNU General Public License v3.0
// Copyright © 2020 Lea (Adrian) Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import Down
import UIKit
import WebKit

class LegalNoticeViewController: UIViewController {
	let legalNotice = """
    // var markdownView: UITextView!
    var webView: WKWebView!
    // font-family: -apple-system, "Helvetica Neue", "Lucida Grande";
    let legalNotice = """
    <html>
    	<head>
    	<style>
    		:root {
    		  color-scheme: light dark;
    		}
    		body {
    			font: -apple-system-body;

    		}
    		footer {
    			font: -apple-system-footnote;
    		}
    		a {
    			color: #0070f3;
    		}
    		img {
    			max-width: 100%;
    		}
    	</style>
    	</head>
    	<body>
    		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0,Proxima Nova-Regular\">
    		<h1>Legal Notice</h1>
    		<p>Information in accordance with Section 5 TMG</p>
    		<p>
    		Adrian Baumgart<br/>
    		Karl-Gehrig-Straße 2<br/>
    		69226 Nußloch<br/>
    		Germany<br/>
    		</p>

    		<h2>Contact Information</h2>

    		<p>
    		Telephone: <a href="tel:+4915165909306">+4915165909306</a><br/>
    		E-Mail: <a href="mailto:lea@abmgrt.dev">lea@abmgrt.dev</a><br/>
    		</p>

    		<h2>Disclaimer</h2>
    		<p>Most of the content within this app is user-generated. We are not responsible for this content. If you want to report an issue regarding this content, please contact the Alles Support.</p>
    	</body>
    </html>
    """

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = SLocale(.LEGAL_NOTICE)
        navigationController?.navigationBar.prefersLargeTitles = false

        webView = WKWebView(frame: .zero)
        webView.loadHTMLString(legalNotice, baseURL: nil)
        // webView.scrollView.isScrollEnabled = false
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = true
        view.addSubview(webView)

        webView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).offset(16)
            make.leading.equalTo(view.snp.leading).offset(16)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
            make.bottom.equalTo(view.snp.bottom).offset(-8)
        }

        /* markdownView = UITextView(frame: .zero)
         markdownView.isEditable = false
         view.addSubview(markdownView!)

         markdownView?.snp.makeConstraints { make in
         	make.top.equalTo(view.snp.top).offset(16)
         	make.leading.equalTo(view.snp.leading).offset(16)
         	make.trailing.equalTo(view.snp.trailing).offset(-16)
         	make.bottom.equalTo(view.snp.bottom).offset(-8)
         } */
    }

    /* override func viewDidAppear(_ animated: Bool) {
     	let styleSheet = traitCollection.userInterfaceStyle == .dark ? "* {font-family: Helvetica; color: #ffffff } code, pre { font-family: Menlo }" : "* {font-family: Helvetica; color: #000000 } code, pre { font-family: Menlo }"

     	//markdownView.attributedText = try? Down(markdownString: legalNotice).toAttributedString(.normalize, stylesheet: styleSheet)
     } */
}

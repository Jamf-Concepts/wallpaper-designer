//
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa
import SafariServices
import WebKit


class SizesVC: NSViewController, WKNavigationDelegate {
            
    @IBOutlet weak var sizeInfo_webview: WKWebView!

    //open link in default browser
    func webView(_ sizeInfo_webview: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Check for links.
//        print("extension")
        if navigationAction.navigationType == .linkActivated {
            // Make sure the URL is set.
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Check for the scheme component.
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if components?.scheme == "http" || components?.scheme == "https" {
                // Open the link in the external browser.
                NSWorkspace.shared.open(URL(string: "https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/")!)
                // Cancel the decisionHandler because we managed the navigationAction.
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let filePath = Bundle.main.path(forResource: "README", ofType: "md")

        let fileUrl = URL(fileURLWithPath: filePath!)
        
        let request = URLRequest(url: fileUrl)
        sizeInfo_webview.navigationDelegate = self
        sizeInfo_webview.load(request)
        
    }
}

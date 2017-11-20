//
//  WebViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import WebKit

class WebViewController: NSViewController {

    @IBOutlet weak var webView1: WKWebView!
    @IBOutlet weak var webView2: WKWebView!
    @IBOutlet weak var webView3: WKWebView!
    @IBOutlet weak var webView4: WKWebView!
    
    private var webViews = [WKWebView!]()
    
    private var observations = [NSKeyValueObservation]()
    private var completions = [((String?)->(Void))?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webViews.append(webView1)
        webViews.append(webView2)
        webViews.append(webView3)
        webViews.append(webView4)
        
        let loadingObservation:(WKWebView, NSKeyValueObservedChange<Bool>)->(Void) = { [weak self] (webView, change) in
            // once loaded
            print("Done loading")
            if (!webView.isLoading) {
                let webViewId = self?.webViews.index(where: { $0 == webView })
                webView.magnification = 0.9         // zoom out a little bit
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html, error) in
                        self?.completions[webViewId!]?(html as? String)
                    }
                }
            }
        }
        
        webViews.forEach {
            $0.allowsMagnification = true           // allow zoom in/out
            completions.append(nil)
            observations.append($0.observe(\.loading, changeHandler: loadingObservation))  // set up KVO for loading status
        }
    }
    
    func getPage(webViewId: Int, url: URL, completion: ((String?)->(Void))?) {
        guard webViewId >= 0 && webViewId < webViews.count else {
            print("Invalid webView ID")
            return
        }
        
        guard let webView = webViews[webViewId] else {
            print("Invalid webView")
            return
        }
        
        print("Requesting \(url) in view \(webViewId)")
        
        completions[webViewId] = completion
        DispatchQueue.main.async {
            webView.load(URLRequest(url: url))
        }
    }
}

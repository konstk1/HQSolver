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
    
    private var webViews = [WKWebView!]()
    
    private var observations = [NSKeyValueObservation]()
    private var dispatchGroups = [DispatchGroup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webViews.append(webView1)
        webViews.append(webView2)
        webViews.append(webView3)
        
        let loadingObservation:(WKWebView, NSKeyValueObservedChange<Bool>)->(Void) = { [weak self] (webView, change) in
            // once loaded
            if (!webView.isLoading) {
//                self?.dispatchGroups[0].leave()
                webView.magnification = 0.9         // zoom out a little bit
            }
        }
        
        webViews.forEach {
            $0.allowsMagnification = true           // allow zoom in/out
            dispatchGroups.append(DispatchGroup())
            observations.append($0.observe(\.loading, changeHandler: loadingObservation))  // set up KVO for loading status
        }
    }
    
    func getPage(webViewId: Int, url: URL) {
        guard webViewId >= 0 && webViewId < webViews.count else {
            print("Invalid webView ID")
            return
        }
        
        if let webView = webViews[webViewId] {
            print("Requesting \(url) in view \(webViewId)")
//            dispatchGroups[webViewId].enter()
            DispatchQueue.main.async {
                webView.load(URLRequest(url: url))
            }
        }
        
//        dispatchGroups[webViewId].wait()
        print("Done loading")
    }
    
}

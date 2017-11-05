//
//  GoogleStrategy.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import WebKit

class GoogleStrategy: TriviaStrategy {
    let name = "Google"
    let baseUrl = "https://www.google.com/search"
    
    private let webViewWindowController: NSWindowController
    private let webViewController: WebViewController
    
    struct Query: Codable {
        let question: String
        let answers: [String]
    }
    
    init() {
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "WebViewController")
        webViewWindowController = NSStoryboard.main?.instantiateController(withIdentifier: identifier) as! NSWindowController
        webViewWindowController.showWindow(nil)
        webViewController = webViewWindowController.contentViewController as! WebViewController
//        webViewController.webView1.webFrame.frameView.documentView.scaleUnitSquare(to: NSMakeSize(0.7, 0.7))
        

    }
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        for (i, answer) in possibleAnswers.enumerated() {
            let url = searchUrl(query: "\(question)")
            print("Requesting \(url) in view \(i)")
            switch i
            {
            case 0:
                webViewController.webView1?.load(URLRequest(url: url))
//            case 1:
//                webViewController.webView2?.load(URLRequest(url: url))
//            case 2:
//                webViewController.webView3?.load(URLRequest(url: url))
            default:
                break
            }
        }
        return "Answering not implemented"
    }
    
    func searchUrl(query: String) -> URL {
        guard var urlComponents = URLComponents(string: baseUrl) else { return URL(string: "www.google.com")! }
        urlComponents.query = "q=\(query)"
        return urlComponents.url ?? URL(string: "www.google.com")!
    }
}

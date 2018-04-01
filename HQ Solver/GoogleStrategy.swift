//
//  GoogleStrategy.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import WebKit
//import Kanna

class GoogleStrategy: TriviaStrategy {
    let name = "Google"
    let baseUrl = "https://www.google.com/search"
    
    private let webViewWindowController: NSWindowController
    private let webViewController: WebViewController
    
    private var observation1: NSKeyValueObservation? = nil
    
    let watson = WatsonNLU()
    
    struct Query: Codable {
        let question: String
        let answers: [String]
    }
    
    init() {
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "WebViewWindowController")
        let controller = NSStoryboard.main?.instantiateController(withIdentifier: identifier)
        webViewWindowController = controller as! NSWindowController
        webViewWindowController.showWindow(nil)
        webViewController = webViewWindowController.contentViewController as! WebViewController

//        webViewController.webView1.webFrame.frameView.documentView.scaleUnitSquare(to: NSMakeSize(0.7, 0.7))
    }
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        for (i, _) in possibleAnswers.enumerated() {
            var searchQuery: String? = nil
            switch i
            {
            case 0:
                searchQuery = question
            case 1:
                guard let analysis = watson.analyze(text: question) else { break }
                searchQuery = analysis.keywords.reduce("") { $0 + " " + $1.text }
//            case 2:
//                webViewController.webView3?.load(URLRequest(url: url))
            default:
                break
            }
            
            if let url = searchUrl(query: searchQuery) {
                webViewController.getPage(webViewId: i, url: url) { [unowned self] html in
                    guard let html = html else { return }
//                    guard let doc = try? HTML(html: html, encoding: .utf8) else {
//                        print("Failed to parse HTML")
//                        return
//                    }
//                    for link in doc.xpath("//h3[@class=\"r\"]/a/@href") {
//                        guard let url = URL(string: "https://www.google.com/\(link.content ?? "")") else { return }
//                        self.webViewController.getPage(webViewId: i+2, url: url, completion: nil)
//                        break
//                    }
                }
            }
        }
        return "Answering not implemented"
    }
    
    func searchUrl(query: String?) -> URL? {
        guard let query = query, query != "" else { return nil }
        var urlComponents = URLComponents(string: baseUrl)!
        urlComponents.query = "q=\(query)"
        return urlComponents.url
    }
}

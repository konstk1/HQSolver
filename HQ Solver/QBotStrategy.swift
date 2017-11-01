//
//  QBotStrategy.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation

class QBotStrategy: TriviaStrategy {
    let name = "QBot"
    let baseUrl = "http://c0f18c59.ngrok.io/question"
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    struct Query: Codable {
        let question: String
        let answers: [String]
    }
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        dataTask?.cancel()
        let query = Query(question: question, answers: possibleAnswers)
        var request = URLRequest(url: URL(string: baseUrl)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try! encoder.encode(query)
        print(String(data: request.httpBody!, encoding: .utf8)!)
        let group = DispatchGroup()
        group.enter()
        dataTask = defaultSession.dataTask(with: request) { [unowned self] (data, response, error) in
            defer {
                self.dataTask = nil
                group.leave()
            }
            if let error = error {
                print("ERROR: Failed to post (\(error))")
            }
            guard let response = response as? HTTPURLResponse else { return }
            print("Response \(response.statusCode)")
        }
    
        dataTask?.resume()
        
        group.wait()
        return "Not implemented"
    }
    
    func queryApi(query: String) {
        dataTask?.cancel()
        // https://api.cognitive.microsoft.com/bing/v7.0/search
        guard var urlComponents = URLComponents(string: baseUrl) else { return }
//        urlComponents.query = query
        guard let url = urlComponents.url else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("e2e2e7b573f34810aa1de005be886e13", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        dataTask = defaultSession.dataTask(with: url) { (data, response, error) in
            defer { self.dataTask = nil }
            
        }
        
        dataTask?.resume()
    }
}

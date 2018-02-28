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
    let baseUrl = "https://helpmetrivia.com"
//    let baseUrl = "http://localhost:3000"
    
    let defaultSession: URLSession
    var dataTask: URLSessionDataTask?
    
    struct Query: Codable {
        let question: String
        let answers: [String]
        let agent = "OCR"
    }
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 1
        defaultSession = URLSession(configuration: config)
    }
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        dataTask?.cancel()
        let query = Query(question: question, answers: possibleAnswers)
        var url = URLComponents(string: baseUrl)!
        url.path = "/question"
        var request = URLRequest(url: url.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try! encoder.encode(query)
//        print(String(data: request.httpBody!, encoding: .utf8)!)
        let group = DispatchGroup()
        var isSubmitted = false
        for i in 1...2 {
            group.enter()
            print("Submitting question (attempt \(i))")
            dataTask = defaultSession.dataTask(with: request) { [unowned self] (data, response, error) in
                defer {
                    self.dataTask = nil
                    group.leave()
                }
                if let error = error as NSError? {
                    if error.code == -1001 {      // timed out
                        // retry
                    }
                    print("ERROR: Failed to post (\(error.code) - \(error))")
                } else {
                    guard let response = response as? HTTPURLResponse else { return }
                    print("Response \(response.statusCode)")
                    isSubmitted = true
                }
            }
            
            dataTask?.resume()
            print("Waiting for response")
            group.wait()
            if isSubmitted { break }
        }
        print("Done")
        return "Not implemented"
    }
    
    func submitAnswer(qNumber: Int, question: String, possibleAnswers: [String], correctAnswer: Int, marked: Bool = false) {
        dataTask?.cancel()
        var url = URLComponents(string: baseUrl)!
        url.path = "/answer"
        var request = URLRequest(url: url.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct Answer: Encodable {
            let questionNumber: Int
            let question: String
            let answers: [String]
            let correctAnswer: Int
            let solution: String
            let marked: Bool
        }
        let solution = 1...3 ~= correctAnswer ? possibleAnswers[correctAnswer-1] : ""
        let answer = Answer(questionNumber: qNumber, question: question, answers: possibleAnswers, correctAnswer: correctAnswer, solution: solution, marked: marked)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        request.httpBody = try! encoder.encode(answer)
        print(String(data: request.httpBody!, encoding: .utf8)!)
        
        dataTask = defaultSession.dataTask(with: request) { [unowned self] (data, response, error) in
            defer { self.dataTask = nil }
            if let error = error {
                print("ERROR: Failed to submit (\(error))")
            }
            guard let response = response as? HTTPURLResponse else { return }
            print("Response \(response.statusCode)")
        }
        dataTask?.resume()
    }
}

extension QBotStrategy {
    static func getNextGame() -> String {
        var nextGame = ""
        var url = URLComponents(string: "https://helpmetrivia.com")!
        url.path = "/next_game"
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let group = DispatchGroup()
        group.enter()
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                group.leave()
            }
            if let error = error {
                print("ERROR: Failed to fetch next game (\(error))")
            }
            guard let _ = response as? HTTPURLResponse else { return }
            guard let data = data else { return }
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else { return }
            guard let game = json["game"] as? String else {
                print("EROR: Game not found \(json)")
                return
            }
            nextGame = game
        }
        dataTask.resume()
        group.wait()
        print("Next game: \(nextGame)")
        return nextGame;
    }
}

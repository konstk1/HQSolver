//
//  TestQuestions.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/29/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import WebKit

class TestQuestions {
    private let examplesFilePath = "/Users/kon/Developer/HQ Solver/HQ Solver/examples.json"
    
    struct Question: Codable {
        let question: String
        let answers: [String]
        let solution: String
    }
    
    let questions: [Question]
    var currentQuestion = -1
    
    init() {
        let text = try! String(contentsOfFile: examplesFilePath)
        questions = try! JSONDecoder().decode([Question].self, from: text.data(using: .utf8)!)
        print(questions)
    }
    
    func nextQuestion() -> Question? {
        currentQuestion = currentQuestion + 1
        if currentQuestion == questions.count {
            currentQuestion = -1                // this will reset question counter for next call
            return nil
        }
        return questions[currentQuestion]
    }
    
    func randomQuestion() -> Question {
        return questions[Int(arc4random_uniform(UInt32(questions.count)))]
    }
    
}

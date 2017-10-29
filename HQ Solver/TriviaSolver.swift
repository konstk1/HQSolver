//
//  TriviaSolver.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation

protocol TriviaStrategy {
    var name: String { get }
    func answerQuestion(question: String, possibleAnswers: [String]) -> String
}

extension TriviaStrategy {
    var name: String { return "Unknown" }
}

class TriviaSolver {
    var strategies = [TriviaStrategy]()
    
    init() {
        
    }
    
    init(strategy: TriviaStrategy) {
        strategies.append(strategy)
    }
    
    func add(strategy: TriviaStrategy) {
        strategies.append(strategy)
    }
    
    func use(strategy: TriviaStrategy) {
        strategies.removeAll()
        strategies.append(strategy)
    }
    
    func solve(question: String, possibleAnswers: [String]) -> String {
        var answer = ""
        for strategy in strategies {
            answer = strategy.answerQuestion(question: question, possibleAnswers: possibleAnswers)
            print("Strategy \(strategy.name): \(answer)")
        }
        // for now return the answer from last strategy used
        return answer
    }
}

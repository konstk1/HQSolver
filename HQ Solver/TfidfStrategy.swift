//
//  TfidfStrategy.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/29/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation

class TfIdfStrategy: TriviaStrategy {
    let name = "TF-IDF"
    let watson = WatsonNLU()
    let google = GoogleStrategy()
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        guard let analysis = watson.analyze(text: question) else { return "Failed to analyze" }
        
        let searchQuery = analysis.keywords.map { $0.text }.joined(separator: " ")
        _ = google.answerQuestion(question: searchQuery, possibleAnswers: possibleAnswers)
        
        return "Not implemented yet"
    }
}


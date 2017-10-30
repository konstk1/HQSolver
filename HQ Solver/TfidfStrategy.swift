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
    
    func answerQuestion(question: String, possibleAnswers: [String]) -> String {
        return "Not implemented yet"
    }
}


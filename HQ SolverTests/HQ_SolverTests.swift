//
//  HQ_SolverTests.swift
//  HQ SolverTests
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import XCTest
@testable import HQ_Solver

class HQ_SolverTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func ztestExample() {
        let testQs = TestQuestions()
        print("Loaded \(testQs.questions.count) questions")
        
        for _ in 0..<testQs.questions.count {
            if let question = testQs.nextQuestion() {
                print("\(testQs.currentQuestion): \(question.question)")
            }
        }
        
        for i in 0..<5 {
            print("Random \(i): \(testQs.randomQuestion().question)")
        }
    }
    
    func testWatson() {
        let watson = WatsonNLU()
        watson.analyze(text: "What U.S. federal agency has an academy in Quantico, Virginia?")
    }
    
//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
    
}

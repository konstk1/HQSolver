//
//  TriviaSolver.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/27/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

protocol TriviaStrategy {
    var name: String { get }
    func answerQuestion(question: String, possibleAnswers: [String]) -> String
}

extension TriviaStrategy {
    var name: String { return "Unknown" }
}

class TriviaSolver {
    var state: State = .waitingForQuestion {
        didSet(newValue) {
            print("State: \(newValue)")
        }
    }
    
    var currentQuestion: Question? = nil       // current question
    var questionNumber = 1
    
    enum State {
        case waitingForQuestion
        case readyForOcr
        case waitingForAnswer
        case waitingForApproval
        case submitting
    }
    
    struct Question {
        var question: String
        var answers: [String]
        var solution: String? = nil
    }
    
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
    
    private func parse(text: String) -> Question {
        var lines = text.split(separator: "\n")
        
        var answers = [String]()
        for answer in [lines.popLast(), lines.popLast(), lines.popLast()].reversed() {
            if let answer = answer {
                answers.append(String(answer))
            }
        }
        
        let question = lines.joined(separator: " ")
        return Question(question: question, answers: answers, solution: nil)
    }
    
    func solve(question: Question) -> String {
        var answer = ""

        currentQuestion = question
        
        for strategy in strategies {
            DispatchQueue.global(qos: .userInitiated).async {
                answer = strategy.answerQuestion(question: question.question, possibleAnswers: question.answers)
//                print("Strategy \(strategy.name): \(answer)")
            }
        }
        // for now return the answer from last strategy used
        return answer
    }
    
    func submit() {
        state = .submitting
        // TODO: submit current question and asnwers to HQBot
        state = .waitingForQuestion
        questionNumber = questionNumber + 1
    }
}

// frame processing
extension TriviaSolver {
    func processFrame(image: NSImage) -> NSImage {
        let ocrImage = prepForOcr(image: image)
        
        if state == .readyForOcr {
            if let text = runOcr(image: ocrImage) {
                state = .waitingForAnswer
                let q = parse(text: text)
                _ = solve(question: q)
            }
        }
        
        return ocrImage
    }
    
    private func prepForOcr(image: NSImage) -> NSImage {
        let opencv =  OpenCV(image: image)
        opencv.prepareForOcr()
        
        print("\(state) - \(opencv.correctAnswer)")
        if state == .waitingForQuestion && opencv.questionMarkPresent {
            state = .readyForOcr
        } else if state == .waitingForAnswer && opencv.correctAnswer > 0 {
            let solution = currentQuestion?.answers[Int(opencv.correctAnswer)]
            currentQuestion?.solution = solution
            state = .waitingForApproval
            // start 3 second timer for auto approval
        }
        
        return opencv.image
    }
    
    private func runOcr(image: NSImage) -> String? {
        let tess = TessBaseAPICreate()
        TessBaseAPIInit3(tess, nil, "eng")
        
        let bmp = image.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        
        //        print("Processing image \(bmp.pixelsWide)x\(bmp.pixelsHigh) \(bmp.bitsPerPixel/8) \(bmp.bytesPerRow)")
        TessBaseAPISetImage(tess, data, Int32(bmp.pixelsWide), Int32(bmp.pixelsHigh), Int32(bmp.bitsPerPixel/8), Int32(bmp.bytesPerRow))
        
        let outText = String(cString: TessBaseAPIGetUTF8Text(tess)!)
        
        TessBaseAPIDelete(tess)
        
        return outText
    }
}

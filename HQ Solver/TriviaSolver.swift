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
    var isReadyForQuestion = true
    var state: State = .waitingForQuestion
    
    var currentQuestion: Question? = nil       // current question
    var questionNumber = 0
    
    enum State {
        case waitingForQuestion
        case waitingForAnswer
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
    
    func parseAndSolve(text: String) {
        var lines = text.split(separator: "\n")
        
        var answers = [String]()
        for answer in [lines.popLast(), lines.popLast(), lines.popLast()].reversed() {
            if let answer = answer {
                answers.append(String(answer))
            }
        }
        
        let question = lines.joined(separator: " ")
        currentQuestion = Question(question: question, answers: answers, solution: nil)
        
        _ = solve()
    }
    
    func solve() -> String {
        var answer = ""
        guard let question = currentQuestion else {
            print("Error: no current question")
            return ""
        }
        
        for strategy in strategies {
            DispatchQueue.global(qos: .userInitiated).async {
                answer = strategy.answerQuestion(question: question.question, possibleAnswers: question.answers)
                print("Strategy \(strategy.name): \(answer)")
            }
        }
        // for now return the answer from last strategy used
        return answer
    }
}

// frame processing
extension TriviaSolver {
    
    func prepForOcr(image: NSImage) -> Bool {
        let startTime = Date()
        
        // Prepare image for OCR with OpenCV
        //        originalImageView.image = image
        
        let opencv =  OpenCV(image: image)
        opencv.prepareForOcr()
        
        let ocrImage = opencv.image
        //        ocrImageView.image = ocrImage
        let openCvDuration = Date().timeIntervalSince(startTime)
        
        //        print("Question: \(opencv.questionMarkPresent)")
        guard isReadyForQuestion && opencv.questionMarkPresent && opencv.correctAnswer == 0 else {
            //            print("Correct answer \(opencv.correctAnswer)")
            isReadyForQuestion = !opencv.questionMarkPresent
            return nil
        }
        
        isReadyForQuestion = false
    }
    
    func runOcr(image: NSImage) -> String? {
        // Run OCR
        let tess = TessBaseAPICreate()
        TessBaseAPIInit3(tess, nil, "eng")
        
        let bmp = ocrImage.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        
        //        print("Processing image \(bmp.pixelsWide)x\(bmp.pixelsHigh) \(bmp.bitsPerPixel/8) \(bmp.bytesPerRow)")
        TessBaseAPISetImage(tess, data, Int32(bmp.pixelsWide), Int32(bmp.pixelsHigh), Int32(bmp.bitsPerPixel/8), Int32(bmp.bytesPerRow))
        
        let outText = String(cString: TessBaseAPIGetUTF8Text(tess)!)
        let endTime = Date()
        self.ocrDuration = endTime.timeIntervalSince(startTime)
        
        
        ocrResultLabel.stringValue = outText
        TessBaseAPIDelete(tess)
        
        return outText
    }
}

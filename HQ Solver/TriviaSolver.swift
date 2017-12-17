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
    func submitAnswer(qNumber: Int, question: String, possibleAnswers: [String], correctAnswer: Int, marked: Bool)
}

extension TriviaStrategy {
    var name: String { return "Unknown" }
    func submitAnswer(qNumber: Int, question: String, possibleAnswers: [String], correctAnswer: Int, marked: Bool) {
        // default implementation
    }
}

protocol TriviaSolverDelegate: class {
    func triviaSolver(solver: TriviaSolver, didUpdateState state: TriviaSolver.State);
}

final class TriviaSolver {
    var state: State = .waitingForQuestion {
        didSet {
            print("State: \(state)")
            delegate?.triviaSolver(solver: self, didUpdateState: state)
        }
    }
    
    weak var delegate: TriviaSolverDelegate? = nil
    var currentQuestion: Question? = nil       // current question
    var questionNumber = 1
    
    enum State {
        case waitingForQuestion
        case readyForOcr
        case waitingForAnswer
        case waitingForApproval
        case submitting
    }
    
    struct Question: Encodable {
        var question: String
        var answers: [String]
        var correctAnswer = -1
        var solution: String? { return 1...3 ~= correctAnswer ? answers[correctAnswer-1] : nil }
        var marked: Bool = false
        
        init(question: String, answers: [String]) {
            self.question = question
            self.answers = answers
        }
    }
    
    struct Stats {
        var startTime = Date()
        var prepForOcrTime: TimeInterval = 0
        var ocrTime: TimeInterval = 0
    }
    
    var stats = Stats()
    
    private var strategies = [TriviaStrategy]()
    
    private let tess = TessBaseAPICreate()
    
    init() {
        TessBaseAPIInit3(tess, nil, "eng")
    }
    
    convenience init(strategy: TriviaStrategy) {
        self.init()
        strategies.append(strategy)
    }
    
    deinit {
        TessBaseAPIDelete(tess)
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
        return Question(question: question, answers: answers)
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
    
    func ocrNow() {
        state = .readyForOcr
    }
    
    func submit() {
        state = .submitting
        for strategy in strategies {
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                guard let q = self.currentQuestion else { return }
                strategy.submitAnswer(qNumber: self.questionNumber, question: q.question, possibleAnswers: q.answers, correctAnswer: q.correctAnswer, marked: q.marked)
            }
        }
        print("Submitting \(currentQuestion!)")
    }
    
    func reset() {
        state = .waitingForQuestion
        currentQuestion = nil
    }
}

// frame processing
extension TriviaSolver {
    func processFrame(image: NSImage) -> NSImage {
        stats.startTime = Date()
        
        // OpenCV to detect state and prepare for OCR
        let opencv =  OpenCV(image: image)
        opencv.prepareForOcr()
        let ocrImage = opencv.image
        
        stats.prepForOcrTime = Date().timeIntervalSince(stats.startTime)
        
//        print("\(state) - \(opencv.correctAnswer)")
        if state == .waitingForQuestion && opencv.questionMarkPresent {
            state = .readyForOcr
        } else if state == .waitingForAnswer && opencv.correctAnswer > 0 {
            currentQuestion?.correctAnswer =  Int(opencv.correctAnswer)
            state = .waitingForApproval
            // wait 3 seconds for auto approval
//            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) { [unowned self] in
//                print("Timer fired, submitting")
//                self.submit()
//            }
        } else if state == .waitingForApproval && opencv.correctAnswer == 0 {
            self.submit()
            // wait for correct answer disappear, now ready for next question
            currentQuestion = nil
            questionNumber = questionNumber + 1
            state = .waitingForQuestion
        }
        
        if state == .readyForOcr {
            if let text = runOcr(image: ocrImage) {
                stats.ocrTime = Date().timeIntervalSince(stats.startTime) - stats.prepForOcrTime
                let q = parse(text: text)
                _ = solve(question: q)
                state = .waitingForAnswer
            }
        }
        
        return ocrImage
    }
    
    private func runOcr(image: NSImage) -> String? {
        let bmp = image.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        
        // print("Processing image \(bmp.pixelsWide)x\(bmp.pixelsHigh) \(bmp.bitsPerPixel/8) \(bmp.bytesPerRow)")
        TessBaseAPISetImage(tess, data, Int32(bmp.pixelsWide), Int32(bmp.pixelsHigh), Int32(bmp.bitsPerPixel/8), Int32(bmp.bytesPerRow))
        
        return String(cString: TessBaseAPIGetUTF8Text(tess)!)
    }
}

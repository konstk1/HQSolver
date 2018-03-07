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
    
    var gameTitle = ""
    
    var device: Int = 0
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
        print("Adding \(strategy.name)")
        strategies.append(strategy)
    }
    
    func removeStrategy(named: String) {
        guard let idx = (strategies.index { $0.name == named }) else { return }
        print("Removing \(strategies[idx].name)")
        strategies.remove(at: idx)
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
        guard let question = currentQuestion else { return }
        print("Submitting \(question)")
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
//        if gameTitle.lowercased().contains("cash") {
//            let opencv =  OpenCVCashShow(image: image, device: Int32(device))
//        } else if gameTitle.lowercased().contains("quiz") {
//            let opencv =  OpenCVQB(image: image, device: Int32(device))
//        } else {
//            print("ERROR: unsupported game")
//        }
        
//        let opencv =  OpenCVQB(image: image, device: Int32(device))
        let opencv =  OpenCVCashShow(image: image, device: Int32(device))
        
        opencv.prepareForOcr()
        let ocrImages = opencv.images as! [NSImage]
        
        stats.prepForOcrTime = Date().timeIntervalSince(stats.startTime)
        
//        print("\(state) - \(opencv.correctAnswer)")
        if state == .waitingForQuestion && opencv.questionMarkPresent && opencv.correctAnswer == 0 {
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
            if let text = runOcr(image: ocrImages[0]) {
                stats.ocrTime = Date().timeIntervalSince(stats.startTime) - stats.prepForOcrTime
                var q: Question
                if ocrImages.count == 1 {       // HQ style (combined question and answers)
                    q = parse(text: text)
                    _ = solve(question: q)
                } else if ocrImages.count == 4 {     // Cash Show style (split)
                    let question = text.replacingOccurrences(of: "\n", with: " ").removingRegexMatches(pattern: "^[\\— ]*\\d+. *")
                    var answers = [String]()
                    for i in 1...3 {
                        var answer = runOcr(image: ocrImages[i])
                        answer = answer?.trimmingCharacters(in: .whitespacesAndNewlines)
                        answer = answer?.removingRegexMatches(pattern: "[| ]*$")
                        answers.append(answer ?? "")
                    }
                    q = Question(question: question, answers: answers)
                    _ = solve(question: q)
                } else {
                    print("ERROR: incorrect number of images \(ocrImages.count)")
                }
                
                state = .waitingForAnswer
            }
        }
        
        return ocrImages.count > 0 ? ocrImages[0] : NSImage();
    }
    
    private func runOcr(image: NSImage) -> String? {
        let bmp = image.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        
        // print("Processing image \(bmp.pixelsWide)x\(bmp.pixelsHigh) \(bmp.bitsPerPixel/8) \(bmp.bytesPerRow)")
        TessBaseAPISetImage(tess, data, Int32(bmp.pixelsWide), Int32(bmp.pixelsHigh), Int32(bmp.bitsPerPixel/8), Int32(bmp.bytesPerRow))
        
        return String(cString: TessBaseAPIGetUTF8Text(tess)!)
    }
}

extension String {
    func removingRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return self
        }
    }
}

//Submitting Question(question: "— 7. Which is a song by The Presidents of the United States of America? ", answers: ["“Apples” |", "“Peaches” |", "\"Grapes\" |"], correctAnswer: 2, marked: false)
//{
//    "marked" : false,
//    "answers" : [
//    "“Apples” |",
//    "“Peaches” |",
//    "\"Grapes\" |"
//    ],
//    "questionNumber" : 7,
//    "question" : "— 7. Which is a song by The Presidents of the United States of America? ",
//    "correctAnswer" : 2,
//    "solution" : "“Peaches” |"
//}

//Submitting Question(question: "Which of these animal young is amammal? ", answers: ["Shoat I", "Nymph I", "Polliwog I"], correctAnswer: 1, marked: false)
//State: waitingForQuestion
//{
//    "marked" : false,
//    "answers" : [
//    "Shoat I",
//    "Nymph I",
//    "Polliwog I"
//    ],
//    "questionNumber" : 7,
//    "question" : "Which of these animal young is amammal? ",
//    "correctAnswer" : 1,
//    "solution" : "Shoat I"
//}



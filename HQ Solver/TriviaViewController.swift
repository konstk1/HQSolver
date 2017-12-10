//
//  TriviaViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

class TriviaViewController: NSViewController, TriviaSolverDelegate {
    
    let screenCap = ScreenCap(displayId: 0, maxFrameRate: 30)
    let captureInterval: TimeInterval = 0.1
    var captureTimer: Timer?
    
    var chosenAnswer = 0
    let solver = TriviaSolver()

    @IBOutlet weak var originalImageView: NSImageView!
    @IBOutlet weak var ocrImageView: NSImageView!
    @IBOutlet weak var ocrResultLabel: NSTextField!
    @IBOutlet weak var statsLabel: NSTextField!
    @IBOutlet weak var questionNumberLabel: NSTextField!
    
    @IBOutlet weak var answer1Button: NSButton!
    @IBOutlet weak var answer2Button: NSButton!
    @IBOutlet weak var answer3Button: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawBorder(view: originalImageView, width: 1, color: NSColor.green)
        drawBorder(view: ocrImageView, width: 1, color: NSColor.blue)
        
        solver.delegate = self
        solver.add(strategy: QBotStrategy())
        solver.add(strategy: GoogleStrategy())
        
        screenCap?.startCaputre()
        screenCap?.cropRect = CGRect(x: 0, y: 100, width: 550, height: 760)

        captureTimer = Timer.scheduledTimer(timeInterval: captureInterval, target: self, selector: #selector(processFrame), userInfo: nil, repeats: true)

    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        screenCap?.stopCapture()
        captureTimer?.invalidate()
    }
    
    func triviaSolver(solver: TriviaSolver, didUpdateState state: TriviaSolver.State) {
        DispatchQueue.main.async { [unowned self] in
            self.questionNumberLabel.stringValue = "Q\(solver.questionNumber)"
            if let q = solver.currentQuestion {
                self.ocrResultLabel.stringValue = q.question
                self.answer1Button.title = q.answers[0]
                self.answer2Button.title = q.answers[1]
                self.answer3Button.title = q.answers[2]
                
                self.selectAnswerOption(answer: q.correctAnswer)
            } else {
                self.ocrResultLabel.stringValue = "Waiting for question..."
                self.answer1Button.title = "1"
                self.answer2Button.title = "2"
                self.answer3Button.title = "3"
                [self.answer1Button, self.answer2Button, self.answer3Button].forEach { $0?.layer?.backgroundColor = nil }
            }
        }
    }
    
    @objc func processFrame() {
        screenCap?.getImage(completion: { [unowned self] (image) in
            let ocrImage = self.solver.processFrame(image: image)
            
            // update UI
            DispatchQueue.main.async {
                self.ocrImageView.image = ocrImage
            }
        })
    }

    func selectAnswerOption(answer: Int) {
        let buttons = [answer1Button, answer2Button, answer3Button]
        buttons.forEach {
            $0?.layer?.backgroundColor = nil
        }
        guard 1...3 ~= answer else { return }
        chosenAnswer = answer
        solver.currentQuestion?.correctAnswer = chosenAnswer
        buttons[chosenAnswer-1]?.layer?.backgroundColor = NSColor.green.cgColor
    }
    
    @IBAction func ocrNowPushed(_ sender: NSButton) {
        solver.ocrNow()
    }

    @IBAction func markPushed(_ sender: NSButton) {
        solver.currentQuestion?.marked = true
        ocrResultLabel.backgroundColor = NSColor.yellow
    }
    
    @IBAction func testPushed(_ sender: NSButton) {
        let testQ = TestQuestions().randomQuestion()
        let question = TriviaSolver.Question(question: testQ.question, answers: testQ.answers)
        _ = solver.solve(question: question)
    }
    
    @IBAction func answerPushed(_ sender: NSButton) {
        var answer = 0
        switch sender {
        case answer1Button:
            answer = 1
        case answer2Button:
            answer = 2
        case answer3Button:
            answer = 3
        default:
            print("Invalid answer button pushed")
        }
        
        selectAnswerOption(answer: answer)
    }
}

extension TriviaViewController {
    func drawBorder(view: NSView, width: Int, color: NSColor) {
        view.wantsLayer = true
        view.layer?.borderWidth = 1.0
        view.layer?.cornerRadius = 0.0
        view.layer?.masksToBounds = true
        view.layer?.borderColor = color.cgColor
    }
}


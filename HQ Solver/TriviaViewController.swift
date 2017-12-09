//
//  TriviaViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

class TriviaViewController: NSViewController {
    
    let screenCap = ScreenCap(displayId: 0, maxFrameRate: 30)
    let captureInterval: TimeInterval = 0.1
    var captureTimer: Timer?
    
    let solver = TriviaSolver()

    @IBOutlet weak var originalImageView: NSImageView!
    @IBOutlet weak var ocrImageView: NSImageView!
    @IBOutlet weak var ocrResultLabel: NSTextField!
    @IBOutlet weak var statsLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawBorder(view: originalImageView, width: 1, color: NSColor.green)
        drawBorder(view: ocrImageView, width: 1, color: NSColor.blue)
        
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
    
    @objc func processFrame() {
        screenCap?.getImage(completion: { [unowned self] (image) in
            let ocrImage = self.solver.processFrame(image: image)
            
            // update UI
            DispatchQueue.main.async {
                self.ocrImageView.image = ocrImage
            }
        })
    }

    @IBAction func doItPushed(_ sender: NSButton) {
//        isReadyForQuestion = true
    }
    
    @IBAction func testPushed(_ sender: NSButton) {
        let testQ = TestQuestions().randomQuestion()
        let question = TriviaSolver.Question(question: testQ.question, answers: testQ.answers, solution: nil)
        _ = solver.solve(question: question)
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


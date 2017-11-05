//
//  ViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let screenCap = ScreenCap(displayId: 0, maxFrameRate: 30)
    let captureInterval: TimeInterval = 0.1

    var openCvDuration: TimeInterval = 0
    var ocrDuration:    TimeInterval = 0
    var totalDuration:  TimeInterval = 0
    
    var isReadyForQuestion = true
    let solver = TriviaSolver()

    @IBOutlet weak var originalImageView: NSImageView!
    @IBOutlet weak var ocrImageView: NSImageView!
    @IBOutlet weak var ocrResultLabel: NSTextField!
    @IBOutlet weak var statsLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawBorder(view: originalImageView, width: 1, color: NSColor.green)
        drawBorder(view: ocrImageView, width: 1, color: NSColor.blue)
        
//        solver.add(strategy: QBotStrategy())
        solver.add(strategy: TfIdfStrategy())
        
        screenCap?.startCaputre()
//        screenCap?.cropRect = CGRect(x: 30, y: 280, width: 445, height: 460)
        screenCap?.cropRect = CGRect(x: 0, y: 100, width: 550, height: 760)

        Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [unowned self] (timer) in
            self.processFrame()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        screenCap?.stopCapture()
    }
    
    func processFrame() {
        let startTime = Date()
        screenCap?.getImage(completion: { [unowned self] (image) in
            DispatchQueue.main.async { [unowned self] in
                if let text = self.runOcr(image: image) {
                    self.parseAndSolve(text: text)
                }
                let endTime = Date()
                self.totalDuration = endTime.timeIntervalSince(startTime)
                self.statsLabel.stringValue = """
                Cap Freq\t:\t\(String(format: "%4.1f", 1/self.captureInterval)) fps
                Cap Time\t:\t\(String(format: "%4.0f", (self.totalDuration - self.ocrDuration) * 1000)) ms
                OpenCV\t:\t\(String(format: "%4.0f", self.openCvDuration * 1000)) ms
                OCR Time\t:\t\(String(format: "%4.0f", self.ocrDuration * 1000)) ms
                Total\t:\t\(String(format: "%4.0f", self.totalDuration  * 1000)) ms
                """
            }
        })
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
        
        _ = solver.solve(question: question, possibleAnswers: answers)
    }
    
    func runOcr(image: NSImage) -> String? {
        let startTime = Date()
        
        // Prepare image for OCR with OpenCV
        originalImageView.image = image
        
        let opencv =  OpenCV(image: image)
        opencv.prepareForOcr()
        
        let ocrImage = opencv.image
        ocrImageView.image = ocrImage
        self.openCvDuration = Date().timeIntervalSince(startTime)
        
        print("Question: \(opencv.questionMarkPresent)")
        guard isReadyForQuestion && opencv.questionMarkPresent else {
            isReadyForQuestion = !opencv.questionMarkPresent
            return nil
        }
        
        isReadyForQuestion = false
        
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

    @IBAction func doItPushed(_ sender: NSButton) {
        isReadyForQuestion = true
    }
    
    @IBAction func testPushed(_ sender: NSButton) {
        let question = TestQuestions().randomQuestion()
        _ = solver.solve(question: question.question, possibleAnswers: question.answers)
    }
    
    override var representedObject: Any? {
        didSet {
        
        }
    }
}

extension ViewController {
    func drawBorder(view: NSView, width: Int, color: NSColor) {
        view.wantsLayer = true
        view.layer?.borderWidth = 1.0
        view.layer?.cornerRadius = 0.0
        view.layer?.masksToBounds = true
        view.layer?.borderColor = color.cgColor
    }
}


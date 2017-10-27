//
//  ViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let screenCap = ScreenCap(displayId: 0, maxFrameRate: 4)

    @IBOutlet weak var originalImageView: NSImageView!
    @IBOutlet weak var ocrImageView: NSImageView!
    @IBOutlet weak var ocrResultLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        runTess(filename: "/Users/kon/Downloads/hq/q1.jpg")
//        openFileDialog()
        screenCap?.startCaputre()
        screenCap?.cropRect = CGRect(x: 30, y: 270, width: 400, height: 420)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] (timer) in
            self.screenCap?.getImage(completion: { (image) in
                DispatchQueue.main.async { [unowned self] in
                    self.runOcr(image: image)
                }
            })
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        screenCap?.stopCapture()
    }
    
    func runOcr(image: NSImage) {
        let startTime = Date()
        let verStr = String(cString: TessVersion()!)
        print("Tesseract \(verStr)")
        
        // Prepare image for OCR with OpenCV
        originalImageView.image = image
        
        let opencv =  OpenCV(image: image)
//        opencv.convertColorSpace(.BGR2GRAY)
//        opencv.crop(to: CGRect(x: 380, y: 100, width: 220, height: 300))
//        opencv.threshold(190)
        opencv.prepareForOcr()
        
        let ocrImage = opencv.image
        ocrImageView.image = ocrImage
        
        // Run OCR
        let tess = TessBaseAPICreate()
        TessBaseAPIInit3(tess, nil, "eng")
        
        let bmp = ocrImage.representations[0] as! NSBitmapImageRep
        let data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
        
        print("Processing image \(bmp.pixelsWide)x\(bmp.pixelsHigh) \(bmp.bitsPerPixel/8) \(bmp.bytesPerRow)")
        TessBaseAPISetImage(tess, data, Int32(bmp.pixelsWide), Int32(bmp.pixelsHigh), Int32(bmp.bitsPerPixel/8), Int32(bmp.bytesPerRow))
        
        let outText = String(cString: TessBaseAPIGetUTF8Text(tess)!)
        let endTime = Date()
        print("OCR:\n \(outText)")
        print("Duration: \(endTime.timeIntervalSince(startTime))")
        
        
        ocrResultLabel.stringValue = outText
        TessBaseAPIDelete(tess)
    }

    override var representedObject: Any? {
        didSet {
        
        }
    }
}


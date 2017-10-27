//
//  ViewController.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/24/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var originalImageView: NSImageView!
    @IBOutlet weak var ocrImageView: NSImageView!
    @IBOutlet weak var ocrResultLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runTess(filename: "/Users/kon/Downloads/hq/q1.jpg")
//        openFileDialog()
    }
    
    func runTess(filename: String) {
        let verStr = String(cString: TessVersion()!)
        print("Tesseract \(verStr)")
        
        // Prepare image for OCR with OpenCV
        let origImg = NSImage(contentsOfFile: filename)!
        originalImageView.image = origImg
        
        let opencv =  OpenCV(image: origImg)
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
        print("OCR:\n \(outText)")
        
        ocrResultLabel.stringValue = outText
        TessBaseAPIDelete(tess)
    }
    
    func openFileDialog() {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose an image";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
//        dialog.allowedFileTypes        = [""];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                print("Chose \(path)")
                runTess(filename: path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }

    override var representedObject: Any? {
        didSet {
        
        }
    }
}


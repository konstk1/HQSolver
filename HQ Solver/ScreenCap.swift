//
//  ScreenCap.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/26/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import AVFoundation

class ScreenCap {
    let capSession: AVCaptureSession
    let screenCapInput: AVCaptureScreenInput
    let imageCapOutput: AVCaptureStillImageOutput
    
    var cropRect: CGRect {
        get {
            return screenCapInput.cropRect
        }
        set(newRect) {
            screenCapInput.cropRect = newRect
            imageCapOutput.outputSettings[AVVideoHeightKey] = newRect.size.height
            imageCapOutput.outputSettings[AVVideoWidthKey] = newRect.size.width
        }
    }
        
    init?(displayId: CGDirectDisplayID, maxFrameRate: Int32) {
        let tempDisplay = CGMainDisplayID()
        capSession = AVCaptureSession()
        capSession.sessionPreset = .photo
        
        screenCapInput = AVCaptureScreenInput(displayID: tempDisplay)
        screenCapInput.minFrameDuration = CMTimeMake(1, maxFrameRate)
        print("Min frame rate: \(screenCapInput.minFrameDuration)")
        guard capSession.canAddInput(screenCapInput) else { return nil }
        capSession.addInput(screenCapInput)
        
        imageCapOutput = AVCaptureStillImageOutput()
        imageCapOutput.outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.jpeg]
        guard capSession.canAddOutput(imageCapOutput) else { return nil }
        capSession.addOutput(imageCapOutput)
    }
    
    func startCaputre() {
        print("Starting screen cap session")
        capSession.startRunning()
    }
    
    func stopCapture() {
        print("Stopping screen cap session")
        capSession.stopRunning()
    }
    
    func getImage(completion: @escaping (NSImage) -> Void) {
        guard let vidConnection = imageCapOutput.connection(with: .video) else {
            print("Failed to get video connection of ImageCaptureOutput")
            return
        }
        imageCapOutput.captureStillImageAsynchronously(from: vidConnection) { (buffer, error) in
            guard error == nil else {
                print("Capture error: \(error!)")
                return
            }
            guard let buffer = buffer else {
                print("Buffer is nil")
                return
            }
            guard let image = NSImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)!) else {
                print("Failed to get image data")
                return
            }
            completion(image)
        }
    }
}

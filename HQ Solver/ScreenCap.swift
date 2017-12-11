//
//  ScreenCap.swift
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/26/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMediaIO

class ScreenCap {
    let capSession: AVCaptureSession
    let imageCapOutput: AVCaptureStillImageOutput
    
    var cropRect: NSRect? = nil
        
    init() {
        capSession = AVCaptureSession()
        capSession.sessionPreset = .photo

        imageCapOutput = AVCaptureStillImageOutput()
        imageCapOutput.outputSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        guard capSession.canAddOutput(imageCapOutput) else {
            print("Failed to add image capture output to session")
            return
        }
        capSession.addOutput(imageCapOutput)
        
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureDeviceWasConnected, object: nil, queue: nil) { (notification) in
            print("Device connected")
            NotificationCenter.default.removeObserver(token as Any)
        }
        
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
        )
        var allow: UInt32 = 1
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &property, 0, nil, UInt32(MemoryLayout.size(ofValue: allow)), &allow)
    }
    
    func refreshDevices() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .muxed)
        print("Getting devices...\(devices.count)")
        return devices.first { $0.localizedName.contains("iPhone") }
    }
    
    func startCaputre() {
        print("Starting screen cap session")
        
        guard let iPhoneDev = refreshDevices(),
            let iPhoneInput = try? AVCaptureDeviceInput(device: iPhoneDev) else {
            print("iPhone not connected")
            return
        }
        
        guard capSession.canAddInput(iPhoneInput) else { return }
        capSession.addInput(iPhoneInput)
        
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
        imageCapOutput.captureStillImageAsynchronously(from: vidConnection) { [unowned self] (buffer, error) in
            guard error == nil else {
                print("Capture error: \(error!)")
                return
            }
            guard let buffer = buffer else {
                print("Buffer is nil")
                return
            }
            
            var image: NSImage!

            if let cropRect = self.cropRect {
                var ciImage = CIImage(cvImageBuffer: CMSampleBufferGetImageBuffer(buffer)!)
                ciImage = ciImage.cropped(to: cropRect)
                ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: 0.4882, y: 0.4882))
                let rep = NSCIImageRep(ciImage: ciImage)
                image = NSImage(size: rep.size)
                image?.addRepresentation(rep)

            }
            
//            guard let image = NSImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)!) else {
//                print("Failed to get image data")
//                return
//            }
            print("Image \(image.size)")
            completion(image)
        }
    }
}

extension NSImage {
    func crop(to rect: NSRect) -> NSImage? {
        guard let rep = self.bestRepresentation(for: rect, context: nil, hints: nil) else {
            print("Failed to get rep for image")
            return nil
        }
        
        let image = NSImage(size: rect.size)
        image.lockFocus()
        defer { image.unlockFocus() }
        
        rep.draw(in: NSMakeRect(0, 0, rect.size.width, rect.size.height) , from: rect, operation: .copy, fraction: 1.0, respectFlipped: false, hints: nil)
        
        return image
    }
}

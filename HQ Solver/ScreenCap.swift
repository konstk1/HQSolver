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
//    let screenCapInput: AVCaptureScreenInput
    let imageCapOutput: AVCaptureStillImageOutput
//    let iPhoneInput: AVCaptureDeviceInput
    
    var cropRect: CGRect {
        get {
            return CGRect()
//            return iPhoneInput.cropRect
        }
        set(newRect) {
//            iPhoneInput.cropRect = newRect
//            imageCapOutput.outputSettings[AVVideoHeightKey] = newRect.size.height
//            imageCapOutput.outputSettings[AVVideoWidthKey] = newRect.size.width
        }
    }
        
    init?(displayId: CGDirectDisplayID, maxFrameRate: Int32) {
        capSession = AVCaptureSession()
        capSession.sessionPreset = .photo

        imageCapOutput = AVCaptureStillImageOutput()
        imageCapOutput.outputSettings = [
            AVVideoCodecKey: AVVideoCodecType.jpeg]
        guard capSession.canAddOutput(imageCapOutput) else { return nil }
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
        
        iPhoneInput.
        
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
//            print("Failed to get video connection of ImageCaptureOutput")
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
//                print("Failed to get image data")
                return
            }
            completion(image)
        }
    }
}

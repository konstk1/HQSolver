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
    var cropRect: NSRect? = nil
    var devices = [AVCaptureDevice]()
    var enableDevices: Bool = false {
        willSet(newValue) {
            var property = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
            )
            var allow: UInt32 = newValue ? 1 : 0
            print("Setting enable devices: \(newValue)")
            CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &property, 0, nil, UInt32(MemoryLayout.size(ofValue: allow)), &allow)
        }
    }
    
    private let capSession: AVCaptureSession
    private let imageCapOutput: AVCaptureStillImageOutput
    
    private var notifications = [NSObjectProtocol]()
        
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
        
        print("Setting notficiations")
        var notif: NSObjectProtocol
        notif = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureDeviceWasConnected, object: nil, queue: nil) { [unowned self] (notification) in
            print("Device connected")
            self.refreshDevices()
            self.startCaputre()
        }
        notifications.append(notif)
        notif = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureDeviceWasDisconnected, object: nil, queue: nil) { [unowned self] (notification) in
            print("Device disconnected")
            self.refreshDevices()
            self.stopCapture()
        }
        notifications.append(notif)
    }
    
    deinit {
        notifications.forEach { NotificationCenter.default.removeObserver($0 as Any) }
        stopCapture()
    }
    
    func refreshDevices() {
        devices.removeAll()
        let iphones = AVCaptureDevice.devices(for: .muxed).filter { $0.localizedName.contains("iPhone") }
        print("Getting devices...\(iphones.count)")
        devices.append(contentsOf: iphones)
    }
    
    func startCaputre() {
        guard !capSession.isRunning else {
            print("Screen cap already running")
            return
        }
        print("Starting screen cap session")
        
        guard let iPhoneDev = devices.first,
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
        
        capSession.inputs.forEach { capSession.removeInput($0) }
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

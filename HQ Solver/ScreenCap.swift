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

class ScreenCap: NSObject, AVCaptureFileOutputRecordingDelegate {
    var cropRect: NSRect? = nil
    var device = 10         // default iPhone X
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
    private let videoFileOutput: AVCaptureMovieFileOutput
    private let audioOutput: AVCaptureAudioPreviewOutput
    
    private var notifications = [NSObjectProtocol]()
        
    override init() {
        capSession = AVCaptureSession()
        capSession.sessionPreset = .high
        
        audioOutput = AVCaptureAudioPreviewOutput()
        audioOutput.volume = 1.0
        capSession.addOutput(audioOutput)
        
        videoFileOutput = AVCaptureMovieFileOutput()
        capSession.addOutput(videoFileOutput)

        imageCapOutput = AVCaptureStillImageOutput()
        imageCapOutput.outputSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        super.init()

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
        
        if iPhoneDev.localizedName.contains("Kon") {      // iPhone X
            cropRect = CGRect(x: 0, y: 2436-1700-50, width: 1126, height: 1556)
            device = 10;
        } else {                                          // iPhone 7
            cropRect = CGRect(x: 0, y: 0, width: 750, height: 1334)
            device = 7;
        }
        
        guard capSession.canAddInput(iPhoneInput) else { return }
        capSession.addInput(iPhoneInput)
        
        capSession.startRunning()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy - HHmmss"
        videoFileOutput.startRecording(to: URL(fileURLWithPath: "/Users/Kon/Downloads/hq/rec/\(formatter.string(from: Date())).mov"), recordingDelegate: self)
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
            var ciImage = CIImage(cvImageBuffer: CMSampleBufferGetImageBuffer(buffer)!)
            
            if let cropRect = self.cropRect {
                ciImage = ciImage.cropped(to: cropRect)
            }
            
            ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: 0.4882, y: 0.4882))
            let rep = NSCIImageRep(ciImage: ciImage)
            image = NSImage(size: rep.size)
            image?.addRepresentation(rep)
            
            completion(image)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording to \(fileURL)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording to \(outputFileURL) (error: \(String(describing: error)))")
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

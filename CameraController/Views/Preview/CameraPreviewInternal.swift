//
//  CameraPreviewInternal.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

final class CameraPreviewInternal: NSView {
    var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureInput: AVCaptureInput?
    
    // Serial queue to handle all blocking AVCaptureSession start/stop and device lock operations
    private let sessionQueue = DispatchQueue(label: "com.itaysoft.CameraController.sessionQueue", qos: .userInitiated)

    init(frame frameRect: NSRect, device: AVCaptureDevice?) {
        captureDevice = device
        captureSession = AVCaptureSession()

        super.init(frame: frameRect)

        // 1. Enable layer-backing for this NSView
        self.wantsLayer = true

        setupPreviewLayer(captureSession)
        
        // 2. Add the sublayer once here instead of during layout
        if let layer = self.layer {
            layer.addSublayer(previewLayer)
        }

        configureDevice(device)
        
        let session = captureSession
        let dev = captureDevice
        sessionQueue.async {
            do {
                try dev?.lockForConfiguration()
                session.startRunning()
                dev?.unlockForConfiguration()
            } catch {
                // Handle error.
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowClosed),
                                               name: .windowClose,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowOpen),
                                               name: .windowOpen,
                                               object: nil)
    }

    private func setupPreviewLayer(_ captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: UserSettings.shared.cameraPreviewSize.getWidth(),
            height: UserSettings.shared.cameraPreviewSize.getHeight()
        )
        previewLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()
        // 3. Only update the bounds here. Do not add or manipulate layers.
        previewLayer.frame = bounds
    }

    func stopRunning() {
        let session = captureSession
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func updateCamera(_ cam: AVCaptureDevice?) {
        if captureDevice != cam {
            let session = captureSession
            sessionQueue.async {
                if session.isRunning {
                    session.stopRunning()
                }
            }

            configureDevice(cam)
            
            let dev = captureDevice
            sessionQueue.async {
                do {
                    try dev?.lockForConfiguration()
                    session.startRunning()
                    dev?.unlockForConfiguration()
                } catch {
                    // Handle error.
                }
            }
        }
    }

    private func configureDevice(_ aDevice: AVCaptureDevice?) {
        guard let device = aDevice else {
            captureDevice = aDevice
            return
        }

        if let input = captureInput {
            captureSession.removeInput(input)
        }

        do {
            captureInput = try AVCaptureDeviceInput(device: device)
        } catch {
            return
        }

        if let input = captureInput,
            captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            return
        }
        captureDevice = device
    }

    @objc
    func windowClosed() {
        stopRunning()
    }

    @objc
    func windowOpen() {
        let session = captureSession
        sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
}

extension CameraPreviewInternal {
    override public func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        window?.performDrag(with: event)
        NSCursor.contextualMenu.set()
    }

    override public func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        NSCursor.contextualMenu.set()
    }

    override public func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)

        NSCursor.arrow.set()
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.contextualMenu.set()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .mouseMoved]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}

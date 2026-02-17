//
//  CameraPrreviewInternal.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import CoreImage

final class CameraPreviewInternal: NSView {
    var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureInput: AVCaptureInput?

    // Crop pipeline properties
    private var videoOutput: AVCaptureVideoDataOutput?
    private var cropProcessor: CropFrameProcessor?
    private var croppedRenderer: CroppedFrameRenderer?
    private(set) var lastCroppedFrame: CIImage?

    var cropState: CropState? {
        didSet {
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                self?.configureCropPipeline()
            }
        }
    }

    init(frame frameRect: NSRect, device: AVCaptureDevice?) {
        captureDevice = device
        captureSession = AVCaptureSession()

        super.init(frame: frameRect)

        setupPreviewLayer(captureSession)

        Task {
            configureDevice(device)
            // lock configuration to keep device.activeFormat
           do {
               try captureDevice?.lockForConfiguration()
                captureSession.startRunning()
               captureDevice?.unlockForConfiguration()
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

        print("🔵 [CameraPreviewInternal] init complete for device: \(device?.localizedName ?? "nil")")
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
        teardownCropPipeline()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        print("🔵 [CameraPreviewInternal] viewDidMoveToWindow, window: \(window != nil ? "exists" : "nil")")
        if window != nil {
            configureCropPipeline()
        }
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
        layer?.addSublayer(previewLayer)
        croppedRenderer?.metalLayer.frame = bounds
    }

    func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func updateCamera(_ cam: AVCaptureDevice?) {
        if captureDevice != cam {
            captureSession.stopRunning()

            Task {
                configureDevice(cam)
                // lock configuration to keep device.activeFormat
                do {
                    try captureDevice?.lockForConfiguration()
                    captureSession.startRunning()
                    captureDevice?.unlockForConfiguration()
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
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    // MARK: - Crop Pipeline

    private func configureCropPipeline() {
        print("🔵 [CameraPreviewInternal] configureCropPipeline called, cropState: \(cropState != nil ? "exists" : "nil")")
        guard let cropState = cropState else {
            print("🔵 [CameraPreviewInternal] cropState is nil, calling teardown")
            teardownCropPipeline()
            return
        }

        guard videoOutput == nil else {
            print("🔵 [CameraPreviewInternal] videoOutput already exists, skipping setup")
            return
        }

        guard Thread.isMainThread, window != nil else {
            print("🔵 [CameraPreviewInternal] Not on main thread or no window, async dispatching")
            DispatchQueue.main.async { [weak self] in
                self?.configureCropPipeline()
            }
            return
        }

        print("🔵 [CameraPreviewInternal] Setting up crop pipeline...")

        // Create processor
        guard let processor = CropFrameProcessor(cropState: cropState) else {
            print("🔴 [CameraPreviewInternal] Failed to create CropFrameProcessor")
            return
        }
        self.cropProcessor = processor

        // Create renderer
        guard let renderer = CroppedFrameRenderer() else {
            print("🔴 [CameraPreviewInternal] Failed to create CroppedFrameRenderer")
            return
        }
        self.croppedRenderer = renderer

        // Setup video output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        let queue = DispatchQueue(label: "com.dweebzxx.CameraController.cropQueue")
        output.setSampleBufferDelegate(processor, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(output) else {
            print("🔴 [CameraPreviewInternal] Cannot add video output to session")
            return
        }

        captureSession.beginConfiguration()
        captureSession.addOutput(output)
        captureSession.commitConfiguration()
        self.videoOutput = output

        // Setup frame callback
        processor.onProcessedFrame = { [weak self] ciImage, outputSize in
            guard let self = self else { return }
            self.lastCroppedFrame = ciImage
            self.croppedRenderer?.render(ciImage, outputSize: outputSize)
        }

        // Add metal layer to view
        if let metalLayer = croppedRenderer?.metalLayer {
            metalLayer.frame = bounds
            layer?.addSublayer(metalLayer)
        }

        updateLayerVisibility()
        print("🔵 [CameraPreviewInternal] Crop pipeline setup complete")
    }

    private func teardownCropPipeline() {
        print("🔵 [CameraPreviewInternal] teardownCropPipeline called")

        if let output = videoOutput {
            captureSession.beginConfiguration()
            captureSession.removeOutput(output)
            captureSession.commitConfiguration()
            videoOutput = nil
        }

        croppedRenderer?.metalLayer.removeFromSuperlayer()
        croppedRenderer = nil
        cropProcessor = nil
        lastCroppedFrame = nil

        updateLayerVisibility()
    }

    private func updateLayerVisibility() {
        let cropEnabled = cropState?.isEnabled == true
        previewLayer.isHidden = cropEnabled
        croppedRenderer?.metalLayer.isHidden = !cropEnabled
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

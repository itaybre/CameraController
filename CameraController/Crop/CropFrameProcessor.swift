//
//  CropFrameProcessor.swift
//  CameraController
//
//  Created by dweebzxx on 17/2/26.
//  Copyright © 2026 dweebzxx. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import Metal

final class CropFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let ciContext: CIContext
    private weak var cropState: CropState?
    var onProcessedFrame: ((CIImage, CGSize) -> Void)?
    private var frameCounter: Int = 0

    init?(cropState: CropState) {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            return nil
        }

        self.ciContext = CIContext(mtlDevice: metalDevice)
        self.cropState = cropState
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let cropState = cropState else { return }

        // Skip every other frame when adjusting to reduce CPU load
        if cropState.isAdjusting {
            frameCounter += 1
            if frameCounter % 2 != 0 { return }
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageSize = ciImage.extent.size

        // If crop is disabled or full, pass through unchanged
        if !cropState.isEnabled || cropState.cropRect.isFull {
            DispatchQueue.main.async { [weak self] in
                self?.onProcessedFrame?(ciImage, imageSize)
            }
            return
        }

        // Get crop rect in pixels
        let pixelCropRect = cropState.resolve(for: imageSize)

        // Convert from top-left origin to bottom-left origin (CIImage coordinate system)
        let flippedRect = CGRect(
            x: pixelCropRect.origin.x,
            y: imageSize.height - pixelCropRect.origin.y - pixelCropRect.height,
            width: pixelCropRect.width,
            height: pixelCropRect.height
        )

        // Apply crop
        ciImage = ciImage.cropped(to: flippedRect)

        // Translate to origin
        let transform = CGAffineTransform(translationX: -flippedRect.origin.x, y: -flippedRect.origin.y)
        ciImage = ciImage.transformed(by: transform)

        let outputSize = CGSize(width: pixelCropRect.width, height: pixelCropRect.height)

        DispatchQueue.main.async { [weak self] in
            self?.onProcessedFrame?(ciImage, outputSize)
        }
    }

    func renderCGImage(from ciImage: CIImage) -> CGImage? {
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }
}

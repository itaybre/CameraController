//
//  CropFrameProcessor.swift
//  CameraController
//
//  Created by Itay Brenner on 2/15/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

/// Processes video frames and applies crop filter
final class CropFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let context: CIContext
    private let cropState: CropState
    private var frameCounter: Int = 0
    
    /// Callback for processed frames (called on background queue, dispatch to main for UI)
    var onProcessedFrame: ((CIImage, CGSize) -> Void)?
    
    init(cropState: CropState) {
        self.cropState = cropState
        
        // Create Metal-backed context with no intermediate caching
        let options: [CIContextOption: Any] = [
            .cacheIntermediates: false
        ]
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: metalDevice, options: options)
        } else {
            // Fallback to CPU context if Metal unavailable
            self.context = CIContext(options: options)
        }
        
        super.init()
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Skip frames during adjustment for performance
        if cropState.isAdjusting {
            frameCounter += 1
            if frameCounter % 2 != 0 {
                return
            }
        } else {
            frameCounter = 0
        }
        
        // Extract pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Create CIImage from pixel buffer (zero-copy)
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let originalSize = ciImage.extent.size
        
        // If crop is disabled or full, pass through unchanged
        guard cropState.isEnabled && !cropState.cropRect.isFull else {
            onProcessedFrame?(ciImage, originalSize)
            return
        }
        
        // Convert crop rect from top-left origin to CIImage's bottom-left origin
        let cropRect = cropState.cropRect.pixelRect(for: originalSize)
        let flippedY = originalSize.height - cropRect.origin.y - cropRect.height
        let ciCropRect = CGRect(
            x: cropRect.origin.x,
            y: flippedY,
            width: cropRect.width,
            height: cropRect.height
        )
        
        // Apply crop filter
        ciImage = ciImage.cropped(to: ciCropRect)
        
        // Translate origin to (0,0) for rendering
        ciImage = ciImage.transformed(by: CGAffineTransform(
            translationX: -ciCropRect.origin.x,
            y: -ciCropRect.origin.y
        ))
        
        // Call callback with processed image
        onProcessedFrame?(ciImage, ciCropRect.size)
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Expected under load, no-op
    }
    
    /// Render CIImage to CGImage (CPU readback, only for export)
    func renderCGImage(from ciImage: CIImage) -> CGImage? {
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

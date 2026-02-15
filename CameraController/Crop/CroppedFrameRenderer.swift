//
//  CroppedFrameRenderer.swift
//  CameraController
//
//  Created by Itay Brenner on 2/15/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation
import Metal
import CoreImage
import QuartzCore

/// Metal-backed renderer for cropped video frames
final class CroppedFrameRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let context: CIContext
    
    /// The Metal layer to render into
    let metalLayer: CAMetalLayer
    
    /// Failable initializer - returns nil if Metal is unavailable
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // Create CIContext with Metal device
        self.context = CIContext(mtlDevice: device)
        
        // Configure Metal layer
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.contentsGravity = .resizeAspect
    }
    
    /// Render a CIImage into the Metal layer
    func render(_ image: CIImage, outputSize: CGSize) {
        // Update layer drawable size if needed
        let scale = metalLayer.contentsScale
        let drawableSize = CGSize(
            width: outputSize.width * scale,
            height: outputSize.height * scale
        )
        
        if metalLayer.drawableSize != drawableSize {
            metalLayer.drawableSize = drawableSize
        }
        
        // Get drawable
        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // Create render destination
        let destination = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: metalLayer.pixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { () -> MTLTexture in
                return drawable.texture
            }
        )
        
        // Render image to destination
        do {
            // Scale image to fit drawable size
            let scaleX = drawableSize.width / image.extent.width
            let scaleY = drawableSize.height / image.extent.height
            let scaledImage = image.transformed(by: CGAffineTransform(
                scaleX: scaleX,
                y: scaleY
            ))
            
            try context.startTask(toRender: scaledImage, to: destination)
        } catch {
            // Rendering error - skip this frame
            return
        }
        
        // Present drawable
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

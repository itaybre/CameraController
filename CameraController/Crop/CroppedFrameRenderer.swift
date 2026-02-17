//
//  CroppedFrameRenderer.swift
//  CameraController
//
//  Created by dweebzxx on 17/2/26.
//  Copyright © 2026 dweebzxx. All rights reserved.
//

import Foundation
import CoreImage
import Metal
import QuartzCore

final class CroppedFrameRenderer {
    let metalLayer: CAMetalLayer
    private let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }

        self.metalDevice = device
        self.commandQueue = queue
        self.ciContext = CIContext(mtlDevice: device)

        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = false
    }

    func render(_ image: CIImage, outputSize: CGSize) {
        metalLayer.drawableSize = outputSize

        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        let bounds = CGRect(origin: .zero, size: outputSize)
        ciContext.render(image, to: drawable.texture, commandBuffer: commandBuffer, bounds: bounds, colorSpace: CGColorSpaceCreateDeviceRGB())

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

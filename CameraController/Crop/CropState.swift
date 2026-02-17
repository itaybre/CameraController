//
//  CropState.swift
//  CameraController
//
//  Created by dweebzxx on 17/2/26.
//  Copyright © 2026 dweebzxx. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine

/// Normalized crop rectangle with origin in top-left corner (0,0) to bottom-right (1,1)
/// Note: CIImage uses bottom-left origin; conversion happens in CropFrameProcessor
struct NormalizedCropRect: Codable, Equatable {
    var originX: CGFloat
    var originY: CGFloat
    var width: CGFloat
    var height: CGFloat

    static let full = NormalizedCropRect(originX: 0, originY: 0, width: 1, height: 1)

    var isFull: Bool {
        self == .full
    }

    var cgRect: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }

    func pixelRect(for size: CGSize) -> CGRect {
        CGRect(
            x: originX * size.width,
            y: originY * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }

    static func fromPixelRect(_ rect: CGRect, frameSize: CGSize) -> NormalizedCropRect {
        NormalizedCropRect(
            originX: rect.origin.x / frameSize.width,
            originY: rect.origin.y / frameSize.height,
            width: rect.width / frameSize.width,
            height: rect.height / frameSize.height
        )
    }

    func clamped() -> NormalizedCropRect {
        let minDimension: CGFloat = 0.05
        let clampedWidth = max(minDimension, min(1.0 - originX, width))
        let clampedHeight = max(minDimension, min(1.0 - originY, height))
        let clampedOriginX = max(0, min(1.0 - clampedWidth, originX))
        let clampedOriginY = max(0, min(1.0 - clampedHeight, originY))

        return NormalizedCropRect(
            originX: clampedOriginX,
            originY: clampedOriginY,
            width: clampedWidth,
            height: clampedHeight
        )
    }
}

enum AspectRatioPreset: String, CaseIterable, Identifiable, Codable {
    case free
    case ratio16x9 = "16:9"
    case ratio4x3 = "4:3"
    case ratio1x1 = "1:1"
    case ratio9x16 = "9:16"

    var id: String { rawValue }

    var ratio: CGFloat? {
        switch self {
        case .free:
            return nil
        case .ratio16x9:
            return 16.0 / 9.0
        case .ratio4x3:
            return 4.0 / 3.0
        case .ratio1x1:
            return 1.0
        case .ratio9x16:
            return 9.0 / 16.0
        }
    }
}

final class CropState: ObservableObject {
    // MARK: - TEST VALUES (revert to false and .full after Segment 1a testing)
    @Published var isEnabled: Bool = true
    @Published var cropRect: NormalizedCropRect = NormalizedCropRect(
        originX: 0.25, originY: 0.25, width: 0.5, height: 0.5
    )

    @Published var aspectRatio: AspectRatioPreset = .free
    @Published var isAdjusting: Bool = false

    let deviceID: String

    init(deviceID: String) {
        self.deviceID = deviceID
    }

    func resolve(for frameSize: CGSize) -> CGRect {
        let clamped = cropRect.clamped()
        return clamped.pixelRect(for: frameSize)
    }

    func reset() {
        isEnabled = false
        cropRect = .full
        aspectRatio = .free
        isAdjusting = false
    }

    func toStorable() -> StorableCropState {
        StorableCropState(
            isEnabled: isEnabled,
            cropRect: cropRect,
            aspectRatio: aspectRatio
        )
    }

    func apply(_ stored: StorableCropState) {
        isEnabled = stored.isEnabled
        cropRect = stored.cropRect
        aspectRatio = stored.aspectRatio
    }
}

struct StorableCropState: Codable {
    let isEnabled: Bool
    let cropRect: NormalizedCropRect
    let aspectRatio: AspectRatioPreset
}

//
//  CropState.swift
//  CameraController
//
//  Created by Itay Brenner on 2/15/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine

// MARK: - NormalizedCropRect

/// A crop rectangle in normalized coordinates (0.0-1.0), with origin at top-left
struct NormalizedCropRect: Codable, Equatable {
    var originX: CGFloat
    var originY: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    /// Full frame crop rect (no cropping)
    static let full = NormalizedCropRect(originX: 0, originY: 0, width: 1, height: 1)
    
    /// Minimum dimension as fraction of frame (5%)
    private static let minDimension: CGFloat = 0.05
    
    /// Check if this is the full frame (no crop)
    var isFull: Bool {
        return originX == 0 && originY == 0 && width == 1 && height == 1
    }
    
    /// Convert to CGRect
    var cgRect: CGRect {
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    /// Convert to pixel coordinates for given frame size
    func pixelRect(for size: CGSize) -> CGRect {
        return CGRect(
            x: originX * size.width,
            y: originY * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }
    
    /// Create from pixel rect and frame size
    static func fromPixelRect(_ rect: CGRect, frameSize: CGSize) -> NormalizedCropRect {
        guard frameSize.width > 0 && frameSize.height > 0 else {
            return .full
        }
        
        return NormalizedCropRect(
            originX: rect.origin.x / frameSize.width,
            originY: rect.origin.y / frameSize.height,
            width: rect.width / frameSize.width,
            height: rect.height / frameSize.height
        )
    }
    
    /// Clamp to valid range [0-1] and enforce minimum dimensions
    func clamped() -> NormalizedCropRect {
        // Clamp dimensions first, ensuring minimum size
        let clampedWidth = max(min(width, 1.0), Self.minDimension)
        let clampedHeight = max(min(height, 1.0), Self.minDimension)
        
        // Clamp origin, ensuring rect stays within bounds
        let maxX = 1.0 - clampedWidth
        let maxY = 1.0 - clampedHeight
        let clampedX = max(min(originX, maxX), 0)
        let clampedY = max(min(originY, maxY), 0)
        
        return NormalizedCropRect(
            originX: clampedX,
            originY: clampedY,
            width: clampedWidth,
            height: clampedHeight
        )
    }
}

// MARK: - AspectRatioPreset

/// Common aspect ratio presets for cropping
enum AspectRatioPreset: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case ratio16x9 = "16:9"
    case ratio4x3 = "4:3"
    case ratio1x1 = "1:1"
    case ratio9x16 = "9:16"
    
    var id: String { rawValue }
    
    /// The aspect ratio value (width / height), or nil for free
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

// MARK: - StorableCropState

/// Codable snapshot of crop state for persistence
struct StorableCropState: Codable {
    let isEnabled: Bool
    let cropRect: NormalizedCropRect
    let aspectRatio: AspectRatioPreset
}

// MARK: - CropState

/// ObservableObject managing crop configuration for a specific camera
final class CropState: ObservableObject {
    /// Whether cropping is enabled
    @Published var isEnabled: Bool = false
    
    /// The crop rectangle in normalized coordinates
    @Published var cropRect: NormalizedCropRect = .full
    
    /// The aspect ratio constraint
    @Published var aspectRatio: AspectRatioPreset = .free
    
    /// Whether user is actively adjusting the crop (used for frame skipping)
    @Published var isAdjusting: Bool = false
    
    /// The camera device ID this crop state is associated with
    let deviceID: String
    
    init(deviceID: String) {
        self.deviceID = deviceID
    }
    
    /// Resolve the effective crop rect for a given frame size
    /// Returns full frame rect when disabled
    func resolve(for frameSize: CGSize) -> CGRect {
        guard isEnabled && !cropRect.isFull else {
            return CGRect(origin: .zero, size: frameSize)
        }
        
        return cropRect.pixelRect(for: frameSize)
    }
    
    /// Reset crop to full frame and free aspect ratio
    func reset() {
        cropRect = .full
        aspectRatio = .free
    }
    
    /// Create a storable snapshot for persistence
    func toStorable() -> StorableCropState {
        return StorableCropState(
            isEnabled: isEnabled,
            cropRect: cropRect,
            aspectRatio: aspectRatio
        )
    }
    
    /// Apply stored state
    func apply(_ stored: StorableCropState) {
        isEnabled = stored.isEnabled
        cropRect = stored.cropRect
        aspectRatio = stored.aspectRatio
    }
}

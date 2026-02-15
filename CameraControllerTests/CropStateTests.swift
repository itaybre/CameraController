//
//  CropStateTests.swift
//  CameraControllerTests
//
//  Created by Itay Brenner on 2/15/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import XCTest
@testable import CameraController

class CropStateTests: XCTestCase {
    func testNormalizedCropRectFull() {
        let rect = NormalizedCropRect.full
        XCTAssertTrue(rect.isFull)
        XCTAssertEqual(rect.originX, 0)
        XCTAssertEqual(rect.originY, 0)
        XCTAssertEqual(rect.width, 1)
        XCTAssertEqual(rect.height, 1)
    }
    
    func testNormalizedCropRectPixelConversion() {
        let rect = NormalizedCropRect(originX: 0.25, originY: 0.25, width: 0.5, height: 0.5)
        let frameSize = CGSize(width: 1000, height: 500)
        let pixelRect = rect.pixelRect(for: frameSize)
        
        XCTAssertEqual(pixelRect.origin.x, 250)
        XCTAssertEqual(pixelRect.origin.y, 125)
        XCTAssertEqual(pixelRect.width, 500)
        XCTAssertEqual(pixelRect.height, 250)
    }
    
    func testNormalizedCropRectFromPixelRect() {
        let pixelRect = CGRect(x: 250, y: 125, width: 500, height: 250)
        let frameSize = CGSize(width: 1000, height: 500)
        let normalized = NormalizedCropRect.fromPixelRect(pixelRect, frameSize: frameSize)
        
        XCTAssertEqual(normalized.originX, 0.25, accuracy: 0.001)
        XCTAssertEqual(normalized.originY, 0.25, accuracy: 0.001)
        XCTAssertEqual(normalized.width, 0.5, accuracy: 0.001)
        XCTAssertEqual(normalized.height, 0.5, accuracy: 0.001)
    }
    
    func testNormalizedCropRectClamping() {
        // Test rect that exceeds bounds
        let rect = NormalizedCropRect(originX: 0.8, originY: 0.8, width: 0.5, height: 0.5)
        let clamped = rect.clamped()
        
        // Width and height should be clamped to fit within bounds
        XCTAssertTrue(clamped.originX + clamped.width <= 1.0)
        XCTAssertTrue(clamped.originY + clamped.height <= 1.0)
        
        // Test rect with too small dimensions
        let tooSmall = NormalizedCropRect(originX: 0, originY: 0, width: 0.01, height: 0.01)
        let clampedSmall = tooSmall.clamped()
        
        XCTAssertGreaterThanOrEqual(clampedSmall.width, 0.05)
        XCTAssertGreaterThanOrEqual(clampedSmall.height, 0.05)
    }
    
    func testAspectRatioPreset() {
        XCTAssertNil(AspectRatioPreset.free.ratio)
        XCTAssertEqual(AspectRatioPreset.ratio16x9.ratio, 16.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(AspectRatioPreset.ratio4x3.ratio, 4.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(AspectRatioPreset.ratio1x1.ratio, 1.0)
        XCTAssertEqual(AspectRatioPreset.ratio9x16.ratio, 9.0 / 16.0, accuracy: 0.001)
    }
    
    func testCropStateInitialization() {
        let state = CropState(deviceID: "test-device")
        XCTAssertEqual(state.deviceID, "test-device")
        XCTAssertFalse(state.isEnabled)
        XCTAssertTrue(state.cropRect.isFull)
        XCTAssertEqual(state.aspectRatio, .free)
        XCTAssertFalse(state.isAdjusting)
    }
    
    func testCropStateResolve() {
        let state = CropState(deviceID: "test")
        let frameSize = CGSize(width: 1920, height: 1080)
        
        // When disabled, should return full frame
        state.isEnabled = false
        let fullRect = state.resolve(for: frameSize)
        XCTAssertEqual(fullRect.origin.x, 0)
        XCTAssertEqual(fullRect.origin.y, 0)
        XCTAssertEqual(fullRect.size.width, frameSize.width)
        XCTAssertEqual(fullRect.size.height, frameSize.height)
        
        // When enabled with crop rect
        state.isEnabled = true
        state.cropRect = NormalizedCropRect(originX: 0.25, originY: 0.25, width: 0.5, height: 0.5)
        let croppedRect = state.resolve(for: frameSize)
        XCTAssertEqual(croppedRect.origin.x, 480)
        XCTAssertEqual(croppedRect.origin.y, 270)
        XCTAssertEqual(croppedRect.size.width, 960)
        XCTAssertEqual(croppedRect.size.height, 540)
    }
    
    func testCropStateReset() {
        let state = CropState(deviceID: "test")
        state.isEnabled = true
        state.cropRect = NormalizedCropRect(originX: 0.25, originY: 0.25, width: 0.5, height: 0.5)
        state.aspectRatio = .ratio16x9
        
        state.reset()
        
        XCTAssertTrue(state.cropRect.isFull)
        XCTAssertEqual(state.aspectRatio, .free)
    }
    
    func testCropStatePersistence() {
        let state = CropState(deviceID: "test")
        state.isEnabled = true
        state.cropRect = NormalizedCropRect(originX: 0.1, originY: 0.2, width: 0.3, height: 0.4)
        state.aspectRatio = .ratio4x3
        
        let storable = state.toStorable()
        XCTAssertTrue(storable.isEnabled)
        XCTAssertEqual(storable.cropRect.originX, 0.1)
        XCTAssertEqual(storable.aspectRatio, .ratio4x3)
        
        let newState = CropState(deviceID: "test2")
        newState.apply(storable)
        XCTAssertTrue(newState.isEnabled)
        XCTAssertEqual(newState.cropRect.originX, 0.1)
        XCTAssertEqual(newState.aspectRatio, .ratio4x3)
    }
}

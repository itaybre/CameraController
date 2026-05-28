//
//  StringTests.swift
//  CameraControllerTests
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import XCTest
import IOKit.usb
@testable import CameraController
@testable import UVC

class StringTests: XCTestCase {
    func testExtractProductAndVendor() throws {
        let modelInfo = "UVC Camera VendorID_1452 ProductID_34068"

        let result = try modelInfo.extractCameraInformation()

        XCTAssertEqual(result.productId, 34068)
        XCTAssertEqual(result.vendorId, 1452)
    }

    func testExtractInvalid() throws {
        let modelInfo = "Some random string"

        XCTAssertThrowsError(try modelInfo.extractCameraInformation())
    }

    func testProfileDecodesLegacyDataWithoutId() throws {
        let data = Data("""
        [{"name":"Legacy","isDefault":false,"settings":null}]
        """.utf8)

        let profiles = try JSONDecoder().decode([Profile].self, from: data)

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name, "Legacy")
        XCTAssertNotNil(profiles.first?.id)
    }

    func testProfilesWithDuplicateNamesAreDistinct() {
        let first = Profile(name: "Same Name", settings: makeDeviceSettings())
        let second = Profile(name: "Same Name", settings: makeDeviceSettings())

        XCTAssertNotEqual(first, second)
    }

    func testUVCDescriptorParserFindsVideoControlIds() {
        let descriptor = parseDescriptor([
            9, 2, 38, 0, 1, 1, 0, 0x80, 50,
            9, 4, 3, 0, 0, 0x0E, 0x01, 0, 0,
            12, 0x24, 0x01, 0x10, 0x01, 20, 0, 0, 0, 0, 0, 0,
            4, 0x24, 0x02, 7,
            4, 0x24, 0x05, 9
        ])

        XCTAssertEqual(descriptor.interfaceID, 3)
        XCTAssertEqual(descriptor.cameraTerminalID, 7)
        XCTAssertEqual(descriptor.processingUnitID, 9)
    }

    func testUVCDescriptorParserRejectsInvalidConfigLength() {
        let descriptor = parseDescriptor([
            9, 2, 4, 0, 1, 1, 0, 0x80, 50
        ])

        XCTAssertEqual(descriptor.interfaceID, -1)
        XCTAssertEqual(descriptor.cameraTerminalID, -1)
        XCTAssertEqual(descriptor.processingUnitID, -1)
    }

    func testUVCDescriptorParserRejectsZeroLengthDescriptor() {
        let descriptor = parseDescriptor([
            9, 2, 12, 0, 1, 1, 0, 0x80, 50,
            0, 4, 0
        ])

        XCTAssertEqual(descriptor.interfaceID, -1)
        XCTAssertEqual(descriptor.cameraTerminalID, -1)
        XCTAssertEqual(descriptor.processingUnitID, -1)
    }

    func testUVCDescriptorParserRejectsTruncatedDescriptor() {
        let descriptor = parseDescriptor([
            9, 2, 12, 0, 1, 1, 0, 0x80, 50,
            9, 4, 0
        ])

        XCTAssertEqual(descriptor.interfaceID, -1)
        XCTAssertEqual(descriptor.cameraTerminalID, -1)
        XCTAssertEqual(descriptor.processingUnitID, -1)
    }

    private func makeDeviceSettings() -> DeviceSettings {
        return DeviceSettings(exposureMode: 0,
                              exposureTime: 0,
                              gain: 0,
                              brightness: 0,
                              contrast: 0,
                              saturation: 0,
                              sharpness: 0,
                              whiteBalanceAuto: false,
                              whiteBalance: 0,
                              powerline: 0,
                              backlightCompensation: 0,
                              zoom: 0,
                              pan: 0,
                              tilt: 0,
                              focusAuto: false,
                              focus: 0)
    }

    private func parseDescriptor(_ descriptorBytes: [UInt8]) -> UVCDescriptor {
        var descriptorBytes = descriptorBytes
        return descriptorBytes.withUnsafeMutableBytes { buffer in
            let descriptor = buffer.baseAddress!.assumingMemoryBound(to: IOUSBConfigurationDescriptor.self)
            return descriptor.proccessDescriptor()
        }
    }
}

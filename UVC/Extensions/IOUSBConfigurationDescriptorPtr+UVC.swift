//
//  IOUSBConfigurationDescriptorPtr+UVC.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import IOKit

extension IOUSBConfigurationDescriptorPtr {
    func proccessDescriptor() -> UVCDescriptor {
        var processingUnitID = -1
        var cameraTerminalID = -1
        var interfaceID = -1

        let remaining = self.pointee.wTotalLength - UInt16(self.pointee.bLength)
        var pointer = UnsafeMutablePointer<UInt8>(OpaquePointer(self))
        pointer = pointer.advanced(by: Int(self.pointee.bLength))

        browseDescriptor(remaining, pointer, &processingUnitID, &cameraTerminalID, &interfaceID)

        return UVCDescriptor(processingUnitID: processingUnitID,
                             cameraTerminalID: cameraTerminalID,
                             interfaceID: interfaceID)
    }

    private func browseDescriptor(_ memory: UInt16, _ pointer: UnsafeMutablePointer<UInt8>,
                                  _ processingUnitID: inout Int,
                                  _ cameraTerminalID: inout Int,
                                  _ interfaceID: inout Int) {
        var remaining = memory
        var currentPointer = pointer

        while remaining > 0 {
            var descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))

            // Malformed/zero-length descriptor: bail out instead of looping forever.
            guard descriptorPointer.pointee.bLength > 0 else {
                return
            }

            if descriptorPointer.pointee.bDescriptorType == kUSBInterfaceDesc {
                let intDesc = UnsafeMutablePointer<IOUSBInterfaceDescriptor>(OpaquePointer(descriptorPointer))
                if !(intDesc.pointee.bInterfaceClass == UVCConstants.classVideo
                    && intDesc.pointee.bInterfaceSubClass == UVCConstants.subclassVideoControl) {

                    guard let stepped = advance(&currentPointer, remaining, by: intDesc.pointee.bLength) else {
                        return
                    }
                    remaining = stepped
                    continue
                }

                guard let stepped = advance(&currentPointer, remaining, by: intDesc.pointee.bLength) else {
                    return
                }
                remaining = stepped
                var remainingUnwrapped = stepped
                descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))

                guard descriptorPointer.pointee.bLength > 0 else {
                    return
                }

                if descriptorPointer.pointee.bDescriptorType != UVCConstants.descriptorTypeInterface {
                    break
                }

                let internalDescriptor = UnsafeMutablePointer<UVC_VCHeaderDescriptor>(OpaquePointer(descriptorPointer))
                if internalDescriptor.pointee.bDescriptorSubType == UVCConstants.subclassVideoControl {
                    let littleEndian = Int(internalDescriptor.pointee.wTotalLength).littleEndian
                    internalDescriptor.pointee.wTotalLength = UInt16(littleEndian)

                    guard internalDescriptor.pointee.bLength > 0,
                          internalDescriptor.pointee.wTotalLength >= internalDescriptor.pointee.bLength,
                          internalDescriptor.pointee.wTotalLength <= remainingUnwrapped else {
                        return
                    }

                    remainingUnwrapped -= internalDescriptor.pointee.wTotalLength
                    remaining = remainingUnwrapped

                    var remainingMemory = internalDescriptor.pointee.wTotalLength
                        - UInt16(internalDescriptor.pointee.bLength)
                    currentPointer = currentPointer.advanced(by: Int(internalDescriptor.pointee.bLength))

                    while remainingMemory > 0 {
                        descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
                        guard descriptorPointer.pointee.bLength > 0 else {
                            return
                        }
                        if descriptorPointer.pointee.bDescriptorType != UVCConstants.descriptorTypeInterface {
                            break
                        }

                        getDeviceId(descriptorPointer, currentPointer, &processingUnitID, &cameraTerminalID)
                        interfaceID = Int(intDesc.pointee.bInterfaceNumber)

                        if interfaceID != -1 && processingUnitID != -1 && cameraTerminalID != -1 {
                            // Found all necessary data, exit
                            // Fix for WB7022 Camera
                            return
                        }

                        let stepResult = advance(&currentPointer, remainingMemory, by: descriptorPointer.pointee.bLength)
                        guard let stepResultUnwrapped = stepResult else { return }
                        remainingMemory = stepResultUnwrapped
                    }
                } else {
                    guard let stepped = advance(&currentPointer, remainingUnwrapped, by: descriptorPointer.pointee.bLength) else {
                        return
                    }
                    remaining = stepped
                }
                break
            } else {
                guard let stepped = advance(&currentPointer, remaining, by: descriptorPointer.pointee.bLength) else {
                    return
                }
                remaining = stepped
            }
        }
    }

    /// Advances `pointer` by `length` bytes and returns the new remaining byte count,
    /// or `nil` if `length` is zero or larger than what remains (malformed descriptor),
    /// which would otherwise cause an infinite loop or an integer underflow crash.
    private func advance(_ pointer: inout UnsafeMutablePointer<UInt8>,
                         _ remaining: UInt16,
                         by length: UInt8) -> UInt16? {
        guard length > 0, UInt16(length) <= remaining else {
            return nil
        }

        pointer = pointer.advanced(by: Int(length))
        return remaining - UInt16(length)
    }

    private func getDeviceId(_ descriptorPointer: InterfaceDescriptorPointer,
                             _ currentPointer: UnsafeMutablePointer<UInt8>,
                             _ processingUnitID: inout Int,
                             _ cameraTerminalID: inout Int) {
        let unitType = UVCConstants.DescriptorSubtype(rawValue: descriptorPointer.pointee.bDescriptorSubType)
        switch unitType {
        case .processingUnit:
            let puPointer = ProcessingUnitDescriptorPointer(OpaquePointer(currentPointer))
            processingUnitID = Int(puPointer.pointee.bUnitID)
        case .inputTerminal:
            let ctPointer = CameraTerminalDescriptorPointer(OpaquePointer(currentPointer))
            cameraTerminalID = Int(ctPointer.pointee.bTerminalID)
        case .none:
            break
        case .selectorUnit:
            break
        case .extensionUnit:
            break
        }
    }
}

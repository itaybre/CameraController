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

        let totalLength = Int(self.pointee.wTotalLength)
        let descriptorLength = Int(self.pointee.bLength)
        guard descriptorLength > 0, totalLength >= descriptorLength else {
            return UVCDescriptor(processingUnitID: processingUnitID,
                                 cameraTerminalID: cameraTerminalID,
                                 interfaceID: interfaceID)
        }

        let remaining = totalLength - descriptorLength
        var pointer = UnsafeMutablePointer<UInt8>(OpaquePointer(self))
        pointer = pointer.advanced(by: descriptorLength)

        browseDescriptor(remaining, pointer, &processingUnitID, &cameraTerminalID, &interfaceID)

        return UVCDescriptor(processingUnitID: processingUnitID,
                             cameraTerminalID: cameraTerminalID,
                             interfaceID: interfaceID)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func browseDescriptor(_ memory: Int, _ pointer: UnsafeMutablePointer<UInt8>,
                                  _ processingUnitID: inout Int,
                                  _ cameraTerminalID: inout Int,
                                  _ interfaceID: inout Int) {
        var remaining = memory
        var currentPointer = pointer

        while remaining > 0 {
            var descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
            let descriptorLength = Int(descriptorPointer.pointee.bLength)
            guard descriptorLength > 0, descriptorLength <= remaining else {
                break
            }

            if descriptorPointer.pointee.bDescriptorType == kUSBInterfaceDesc {
                let intDesc = UnsafeMutablePointer<IOUSBInterfaceDescriptor>(OpaquePointer(descriptorPointer))
                if !(intDesc.pointee.bInterfaceClass == UVCConstants.classVideo
                    && intDesc.pointee.bInterfaceSubClass == UVCConstants.subclassVideoControl) {

                    remaining -= descriptorLength
                    currentPointer = currentPointer.advanced(by: descriptorLength)
                    continue
                }

                remaining -= descriptorLength
                currentPointer = currentPointer.advanced(by: descriptorLength)
                guard remaining > 0 else {
                    break
                }
                descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
                let headerLength = Int(descriptorPointer.pointee.bLength)
                guard headerLength > 0, headerLength <= remaining else {
                    break
                }

                if descriptorPointer.pointee.bDescriptorType != UVCConstants.descriptorTypeInterface {
                    break
                }

                let internalDescriptor = UnsafeMutablePointer<UVC_VCHeaderDescriptor>(OpaquePointer(descriptorPointer))
                if internalDescriptor.pointee.bDescriptorSubType == UVCConstants.subclassVideoControl {
                    let controlLength = Int(internalDescriptor.pointee.wTotalLength)
                    guard controlLength >= headerLength else {
                        break
                    }

                    let boundedControlLength = min(controlLength, remaining)
                    remaining -= boundedControlLength
                    currentPointer = currentPointer.advanced(by: headerLength)
                    var remainingMemory = boundedControlLength - headerLength

                    while remainingMemory > 0 {
                        descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
                        let descriptorLength = Int(descriptorPointer.pointee.bLength)
                        guard descriptorLength > 0, descriptorLength <= remainingMemory else {
                            break
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

                        remainingMemory -= descriptorLength
                        currentPointer = currentPointer.advanced(by: descriptorLength)
                    }
                } else {
                    remaining -= headerLength
                    currentPointer = currentPointer.advanced(by: headerLength)
                }
                break
            } else {
                remaining -= descriptorLength
                currentPointer = currentPointer.advanced(by: descriptorLength)
            }
        }
    }

    private func getDeviceId(_ descriptorPointer: InterfaceDescriptorPointer,
                             _ currentPointer: UnsafeMutablePointer<UInt8>,
                             _ processingUnitID: inout Int,
                             _ cameraTerminalID: inout Int) {
        let unitType = UVCConstants.DescriptorSubtype(rawValue: descriptorPointer.pointee.bDescriptorSubType)
        switch unitType {
        case .processingUnit:
            guard descriptorPointer.pointee.bLength >= 4 else {
                break
            }
            let puPointer = ProcessingUnitDescriptorPointer(OpaquePointer(currentPointer))
            processingUnitID = Int(puPointer.pointee.bUnitID)
        case .inputTerminal:
            guard descriptorPointer.pointee.bLength >= 4 else {
                break
            }
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

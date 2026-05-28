//
//  UnsafeMutablePointer+interface.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

extension UnsafeMutablePointer where Pointee == UnsafeMutablePointer<IOCFPlugInInterface> {
    func getInterface<T>(uuid: CFUUID) throws -> UnsafeMutablePointer<T> {
        var ref: LPVOID?
        guard pointee.pointee.QueryInterface(self, CFUUIDGetUUIDBytes(uuid), &ref) == kIOReturnSuccess,
            let result: UnsafeMutablePointer<T> = ref?.assumingMemoryBound(to: T.self) else {
                throw NSError(domain: #function, code: #line, userInfo: nil)
        }

        return result
    }
}

extension UnsafeMutablePointer where Pointee == UnsafeMutablePointer<IOUSBDeviceInterface> {
    func iterate(interfaceRequest: IOUSBFindInterfaceRequest,
                 handle: (UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>>) throws -> Void) throws {
        var iterator: io_iterator_t = 0
        var interfaceRequest = interfaceRequest
        try withUnsafeMutablePointer(to: &interfaceRequest, { mutatingPointer in
            guard pointee.pointee.CreateInterfaceIterator(self, mutatingPointer, &iterator) == kIOReturnSuccess else {
                throw UVCError.interfaceIteratorCreationFailed
            }
            defer {
                if iterator != 0 {
                   IOObjectRelease(iterator)
                }
            }
            while true {
                let object: io_service_t = IOIteratorNext(iterator)
                guard 0 < object else { break }
                defer { IOObjectRelease(object) }
                try object.ioCreatePluginInterfaceFor(service: kIOUSBInterfaceUserClientTypeID,
                                                      handle: handle)
            }
        })
    }
}

//
//  CaptureDevice.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UVC

final class CaptureDevice: Hashable, ObservableObject {
    let name: String
    let avDevice: AVCaptureDevice?
    let uvcDevice: UVCDevice?
    var controller: DeviceController?

    init(avDevice: AVCaptureDevice) {
        self.avDevice = avDevice
        self.name = avDevice.localizedName
        do {
            self.uvcDevice = try UVCDevice(device: avDevice)
        } catch {
            print("Unable to configure UVC device \(avDevice.localizedName): \(error)")
            self.uvcDevice = nil
        }
        self.controller = DeviceController(properties: uvcDevice?.properties)
    }

    static func == (lhs: CaptureDevice, rhs: CaptureDevice) -> Bool {
        return lhs.avDevice == rhs.avDevice
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(avDevice)
    }

    func isConfigurable() -> Bool {
        return uvcDevice != nil
    }

    func isDefaultDevice() -> Bool {
        return false
    }

    func readValuesFromDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.exposureTime.update()
            controller.whiteBalance.update()
            controller.focusAbsolute.update()
        }
    }

    func writeValuesToDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.writeValues()
        }
    }
}

//
//  BoolCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import UVC

final class BoolCaptureDeviceProperty: ObservableObject {
    private let control: UVCBoolControl

    let isCapable: Bool

    @Published private var internalValue: Bool

    var isEnabled: Bool {
        get {
            return control.isEnabled
        }
        set {
            if newValue != isEnabled {
                internalValue = newValue

                Task {
                    control.isEnabled = newValue
                }
            }
        }
    }

    init(_ control: UVCBoolControl) {
        self.control = control
        isCapable = control.isCapable
        internalValue = control.isEnabled
        isEnabled = control.isEnabled
    }

    func reset() {
        control.isEnabled = control.defaultValue
        internalValue = control.defaultValue
    }

    func write() {
        control.isEnabled = internalValue
    }
}

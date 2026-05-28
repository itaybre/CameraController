//
//  BitmapCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import UVC

final class BitmapCaptureDeviceProperty: ObservableObject {
    private let control: UVCBitmapControl

    let isCapable: Bool

    @Published private var internalValue: UVCBitmapControl.BitmapValue

    var selected: UVCBitmapControl.BitmapValue {
        get {
            return control.current
        }
        set {
            internalValue = newValue

            Task {
                control.current = newValue
            }
        }
    }

    init(_ control: UVCBitmapControl) {
        self.control = control
        internalValue = control.current
        isCapable = control.isCapable
        selected = control.current
    }

    func reset() {
        control.current = control.defaultValue
        internalValue = control.defaultValue
    }

    func write() {
        control.current = internalValue
    }
}

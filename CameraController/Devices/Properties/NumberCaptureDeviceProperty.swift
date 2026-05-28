//
//  IntCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Combine
import UVC

protocol SliderCapableProperty {
    var sliderValue: Float { get set }
    var isCapable: Bool { get }
    var minimum: Float { get }
    var maximum: Float { get }
    var resolution: Float { get }
    var defaultValue: Float { get }
}

final class NumberCaptureDeviceProperty: SliderCapableProperty, ObservableObject {
    private let control: UVCIntControl

    @Published private var internalValue: Float

    var sliderValue: Float {
        get {
            return Float(control.current)
        }
        set {
            if sliderValue != newValue {
                internalValue = newValue
                Task {
                    control.current = Int(newValue)
                }
            }
        }
    }

    let isCapable: Bool
    let minimum: Float
    var maximum: Float
    let resolution: Float
    let defaultValue: Float

    init(_ control: UVCIntControl) {
        self.control = control
        isCapable = control.isCapable
        internalValue = Float(control.defaultValue)
        minimum = Float(control.minimum)
        maximum = Float(control.maximum)
        resolution = Float(control.resolution)
        defaultValue = Float(control.defaultValue)
        internalValue = Float(control.current)
    }

    func reset() {
        control.current = control.defaultValue
        internalValue = Float(control.defaultValue)
    }

    func update() {
        let newValue = control.getCurrent()
        internalValue = Float(newValue)
    }

    func write() {
        control.current = Int(internalValue)
    }
}

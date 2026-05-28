//
//  DeviceController.swift
//  CameraController
//
//  Created by Itay Brenner on 7/23/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Combine
import UVC

final class DeviceController: ObservableObject {
    // Exposure
    lazy var exposureMode = BitmapCaptureDeviceProperty(properties.exposureMode)
    lazy var exposureTime = NumberCaptureDeviceProperty(properties.exposureTime)
    lazy var gain = NumberCaptureDeviceProperty(properties.gain)

    // Image
    lazy var brightness = NumberCaptureDeviceProperty(properties.brightness)
    lazy var contrast = NumberCaptureDeviceProperty(properties.contrast)
    lazy var saturation = NumberCaptureDeviceProperty(properties.saturation)
    lazy var sharpness = NumberCaptureDeviceProperty(properties.sharpness)
    lazy var hue = NumberCaptureDeviceProperty(properties.hue)
    lazy var hueAuto = BoolCaptureDeviceProperty(properties.hueAuto)

    // WhiteBalance
    lazy var whiteBalanceAuto = BoolCaptureDeviceProperty(properties.whiteBalanceAuto)
    lazy var whiteBalance = NumberCaptureDeviceProperty(properties.whiteBalance)

    // PowerLine
    lazy var powerLineFrequency = NumberCaptureDeviceProperty(properties.powerLineFrequency)

    // Backlight Compensation
    lazy var backlightCompensation = NumberCaptureDeviceProperty(properties.backlightCompensation)

    // Orientation
    lazy var zoomAbsolute = NumberCaptureDeviceProperty(properties.zoomAbsolute)
    lazy var panTiltAbsolute = MultipleCaptureDeviceProperty(properties.panTiltAbsolute)
    lazy var rollAbsolute = NumberCaptureDeviceProperty(properties.rollAbsolute)

    // Focus
    lazy var focusAuto = BoolCaptureDeviceProperty(properties.focusAuto)
    lazy var focusAbsolute = NumberCaptureDeviceProperty(properties.focusAbsolute)

    private let properties: UVCDeviceProperties

    init?(properties: UVCDeviceProperties?) {
        guard let properties = properties else {
            return nil
        }
        self.properties = properties
    }

    func writeValues() {
        exposureMode.write()
        exposureTime.write()
        gain.write()
        brightness.write()
        contrast.write()
        saturation.write()
        sharpness.write()
        hue.write()
        hueAuto.write()
        whiteBalanceAuto.write()
        whiteBalance.write()
        powerLineFrequency.write()
        backlightCompensation.write()
        zoomAbsolute.write()
        panTiltAbsolute.write()
        rollAbsolute.write()
        focusAuto.write()
        focusAbsolute.write()
    }

    func getSettings() -> DeviceSettings {
        return DeviceSettings(exposureMode: self.exposureMode.selected.rawValue,
                              exposureTime: self.exposureTime.sliderValue,
                              gain: self.gain.sliderValue,
                              brightness: self.brightness.sliderValue,
                              contrast: self.contrast.sliderValue,
                              saturation: self.saturation.sliderValue,
                              sharpness: self.sharpness.sliderValue,
                              whiteBalanceAuto: self.whiteBalanceAuto.isEnabled,
                              whiteBalance: self.whiteBalance.sliderValue,
                              powerline: self.powerLineFrequency.sliderValue,
                              backlightCompensation: self.backlightCompensation.sliderValue,
                              zoom: self.zoomAbsolute.sliderValue,
                              pan: self.panTiltAbsolute.sliderValue1,
                              tilt: self.panTiltAbsolute.sliderValue2,
                              focusAuto: self.focusAuto.isEnabled,
                              focus: self.focusAbsolute.sliderValue)
    }

    func set(_ deviceSettings: DeviceSettings) {
        self.exposureMode.selected = UVCBitmapControl.BitmapValue(rawValue: deviceSettings.exposureMode) ?? .auto
        self.exposureTime.sliderValue = deviceSettings.exposureTime
        self.gain.sliderValue = deviceSettings.gain
        self.brightness.sliderValue = deviceSettings.brightness
        self.contrast.sliderValue = deviceSettings.contrast
        self.saturation.sliderValue = deviceSettings.saturation
        self.sharpness.sliderValue = deviceSettings.sharpness
        self.whiteBalanceAuto.isEnabled = deviceSettings.whiteBalanceAuto
        self.whiteBalance.sliderValue = deviceSettings.whiteBalance
        self.powerLineFrequency.sliderValue = deviceSettings.powerline
        self.backlightCompensation.sliderValue = deviceSettings.backlightCompensation
        self.zoomAbsolute.sliderValue = deviceSettings.zoom
        self.panTiltAbsolute.sliderValue1 = deviceSettings.pan
        self.panTiltAbsolute.sliderValue2 = deviceSettings.tilt
        self.focusAuto.isEnabled = deviceSettings.focusAuto
        self.focusAbsolute.sliderValue = deviceSettings.focus
    }

    func resetDefault() {
        self.exposureMode.reset()
        self.exposureTime.reset()
        self.gain.reset()
        self.brightness.reset()
        self.contrast.reset()
        self.saturation.reset()
        self.sharpness.reset()
        self.whiteBalanceAuto.reset()
        self.whiteBalance.reset()
        self.powerLineFrequency.reset()
        self.backlightCompensation.reset()
        self.zoomAbsolute.reset()
        self.panTiltAbsolute.reset()
        self.panTiltAbsolute.reset()
        self.focusAuto.reset()
        self.focusAbsolute.reset()
    }
}

//
//  FocusView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct FocusView: View {
    @ObservedObject var focusAuto: BoolCaptureDeviceProperty
    @ObservedObject var focusAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.focusAuto = controller.focusAuto
        self.focusAbsolute = controller.focusAbsolute
    }

    var body: some View {
        GenericControl(value: $focusAbsolute.sliderValue,
                       step: focusAbsolute.resolution,
                       range: focusAbsolute.minimum...focusAbsolute.maximum,
                       defaultValue: focusAbsolute.defaultValue,
                       title: "Focus",
                       imageName: "camera.aperture",
                       auto: $focusAuto.isEnabled)
    }
}

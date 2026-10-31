//
//  BrightnessView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct BrightnessView: View {
    @ObservedObject var brightness: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.brightness = controller.brightness
    }

    var body: some View {
        GenericControl(value: $brightness.sliderValue,
                       step: brightness.resolution,
                       range: brightness.minimum...brightness.maximum,
                       defaultValue: brightness.defaultValue,
                       title: "Brightness",
                       imageName: "sun.max.fill",
                       auto: nil)
    }
}

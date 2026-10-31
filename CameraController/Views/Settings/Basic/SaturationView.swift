//
//  SaturationView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct SaturationView: View {
    @ObservedObject var saturation: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.saturation = controller.saturation
    }

    var body: some View {
        GenericControl(value: $saturation.sliderValue,
                       step: saturation.resolution,
                       range: saturation.minimum...saturation.maximum,
                       defaultValue: saturation.defaultValue,
                       title: "Saturation",
                       imageName: "eyedropper.halffull",
                       auto: nil)
    }
}

//
//  ContrastView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ContrastView: View {
    @ObservedObject var contrast: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.contrast = controller.contrast
    }

    var body: some View {
        GenericControl(value: $contrast.sliderValue,
                       step: contrast.resolution,
                       range: contrast.minimum...contrast.maximum,
                       defaultValue: contrast.defaultValue,
                       title: "Contrast",
                       imageName: "moonphase.first.quarter",
                       auto: nil)
    }
}

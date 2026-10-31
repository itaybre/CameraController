//
//  RollView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct RollView: View {
    @ObservedObject var rollAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.rollAbsolute = controller.rollAbsolute
    }

    var body: some View {
        GenericControl(value: $rollAbsolute.sliderValue,
                       step: rollAbsolute.resolution,
                       range: rollAbsolute.minimum...rollAbsolute.maximum,
                       defaultValue: rollAbsolute.defaultValue,
                       title: "Roll",
                       imageName: "arrow.counterclockwise",
                       auto: nil)
    }
}

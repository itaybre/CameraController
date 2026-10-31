//
//  ZoomView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ZoomView: View {
    @ObservedObject var zoomAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.zoomAbsolute = controller.zoomAbsolute
    }

    var body: some View {
        GenericControl(value: $zoomAbsolute.sliderValue,
                       step: zoomAbsolute.resolution,
                       range: zoomAbsolute.minimum...zoomAbsolute.maximum,
                       defaultValue: zoomAbsolute.defaultValue,
                       title: "Zoom",
                       imageName: "plus.magnifyingglass",
                       auto: nil)
    }
}

//
//  WhiteBalanceView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct WhiteBalanceView: View {
    @ObservedObject var whiteBalanceAuto: BoolCaptureDeviceProperty
    @ObservedObject var whiteBalance: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.whiteBalanceAuto = controller.whiteBalanceAuto
        self.whiteBalance = controller.whiteBalance
    }

    var body: some View {
        GenericControl(value: $whiteBalance.sliderValue,
                       step: whiteBalance.resolution,
                       range: whiteBalance.minimum...whiteBalance.maximum,
                       defaultValue: whiteBalance.defaultValue,
                       title: "White Balance",
                       imageName: "slider.horizontal.3",
                       auto: $whiteBalanceAuto.isEnabled)
    }
}

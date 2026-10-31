//
//  PanTiltView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct PanTiltView: View {
    @ObservedObject var panTiltAbsolute: MultipleCaptureDeviceProperty

    init(controller: DeviceController) {
        self.panTiltAbsolute = controller.panTiltAbsolute
    }

    var body: some View {
        VStack(spacing: Constants.Style.controlsSpacing) {
            SectionView {
                SectionTitle(title: "Tilt",
                             image: Image(systemName: "arrow.up.and.down"))
                HStack {
                    Toggle(isOn: .constant(false))
                        .hidden()
                    Slider(value: $panTiltAbsolute.sliderValue1,
                              step: panTiltAbsolute.resolution1,
                              sliderRange: panTiltAbsolute.minimum1...panTiltAbsolute.maximum1,
                              defaultValue: panTiltAbsolute.defaultValue1)
                }
            }

            SectionView {
                SectionTitle(title: "Pan",
                             image: Image(systemName: "arrow.left.and.right"))
                HStack {
                    Toggle(isOn: .constant(false))
                        .hidden()
                    Slider(value: $panTiltAbsolute.sliderValue2,
                              step: panTiltAbsolute.resolution2,
                              sliderRange: panTiltAbsolute.minimum2...panTiltAbsolute.maximum2,
                              defaultValue: panTiltAbsolute.defaultValue2)
                }
            }
        }
    }
}

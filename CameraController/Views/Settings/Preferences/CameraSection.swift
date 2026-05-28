//
//  CameraSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct CameraSection: View {
    @ObservedObject var manager = DevicesManager.shared

    var body: some View {
        SectionView {
            SectionTitle(title: "Camera",
                         image: Image(systemName: "web.camera"))

            HStack(spacing: 20.0) {
                Text("Camera")
                Spacer()
                Picker(selection: $manager.selectedDevice, label: Text("")) {
                    Text("None").tag(nil as CaptureDevice?)
                    ForEach(manager.devices, id: \.self) { device in
                        Text(displayName(for: device)).tag(device as CaptureDevice?)
                    }
                }.frame(width: 200)
            }
        }
    }

    private func displayName(for device: CaptureDevice) -> String {
        let duplicateNames = manager.devices.filter { $0.name == device.name }
        guard duplicateNames.count > 1,
            let uniqueID = device.avDevice?.uniqueID else {
            return device.name
        }

        return "\(device.name) (\(uniqueID.suffix(6)))"
    }
}

#if DEBUG
struct CameraSection_Previews: PreviewProvider {
    static var previews: some View {
        CameraSection()
    }
}
#endif

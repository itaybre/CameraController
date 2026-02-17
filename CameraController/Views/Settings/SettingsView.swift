//
//  SettingsView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Binding var captureDevice: CaptureDevice?
    @Binding var currentSection: Int?
    @ObservedObject var cropState: CropState

    var body: some View {
        contentView()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Constants.Style.padding)
            .padding(.bottom, Constants.Style.padding)
            .transition(.opacity.animation(.easeOut(duration: 0.25)))
            .id(currentSection)
    }

    @ViewBuilder
    private func contentView() -> some View {
        if currentSection == nil {
            EmptyView()
        } else if currentSection == 3 {
            PreferencesView()
        } else if let controller = captureDevice?.controller {
            if currentSection == 0 {
                BasicSettings(controller: controller)
            } else if currentSection == 1 {
                AdvancedView(controller: controller)
            } else if currentSection == 2 {
                ProfilesView()
            }
        } else {
            UnsupportedView()
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            captureDevice: .constant(nil),
            currentSection: .constant(nil)
        )
    }
}
#endif

//
//  ProfileRow.swift
//  CameraController
//
//  Created by Itay Brenner on 12/8/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

enum ProfileType {
    case defaultProfile
    case custom(Profile)
}

struct ProfileRow: View {
    var name: String
    var profile: ProfileType
    @State private var showIcons = false

    var body: some View {
        SectionView {
            HStack {
                Text(name)
                    .fontWeight(.bold)
                Spacer()

                if showIcons {
                    Button {
                        applyProfile()
                    } label: {
                        Image(systemName: "checkmark")
                    }

                    if case .custom = profile {
                        Button {
                            deleteProfile()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                } else {
                    Button("") {}
                        .hidden()
                }
            }
        }
        .onHover { isHovering in
            showIcons = isHovering
        }
    }

    private func applyProfile() {
        guard let device = DevicesManager.shared.selectedDevice else {
            return
        }

        switch profile {
        case .defaultProfile:
            device.controller?.resetDefault()
        case .custom(let profile):
            guard let settings = profile.settings else {
                return
            }
            device.controller?.set(settings)
        }
    }

    private func deleteProfile() {
        guard case let .custom(profile) = profile else {
            return
        }
        withAnimation {
            ProfileManager.shared.deleteProfile(profile)
        }
    }
}

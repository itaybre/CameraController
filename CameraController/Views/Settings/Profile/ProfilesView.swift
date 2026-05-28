//
//  ProfilesView.swift
//  CameraController
//
//  Created by Itay Brenner on 26/6/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ProfilesView: View {
    @ObservedObject var profileManager = ProfileManager.shared

    @State private var isAddingProfile = false
    @State private var profileName = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Constants.Style.controlsSpacing) {
                ProfileRow(name: "Camera Default", profile: .defaultProfile)
                Divider()
                ForEach(profileManager.profiles, id: \.id) { profile in
                    ProfileRow(name: profile.name, profile: .custom(profile))
                }
            }
            .padding(.top, 2)
            .padding(.bottom, Constants.Style.topSpacing)

            Button("Save Current Profile") {
                isAddingProfile.toggle()
            }
            .alert("Save Profile", isPresented: $isAddingProfile) {
                TextField("Name", text: $profileName)
                Button("Save", action: {
                    addNewProfile()
                    isAddingProfile = false
                })
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enter the name for your profile")
            }
        }
        .frame(maxHeight: 300)
    }

    private func addNewProfile() {
        guard let device = DevicesManager.shared.selectedDevice,
            let controller = device.controller else {
            return
        }

        withAnimation {
            profileManager.saveProfile(profileName, controller.getSettings())
            profileName = ""
        }
    }
}

#if DEBUG
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesView()
    }
}
#endif

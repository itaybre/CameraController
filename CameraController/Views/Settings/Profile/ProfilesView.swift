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
    @ObservedObject var scheduleManager = ScheduleManager.shared

    @State private var isAddingProfile = false
    @State private var profileName = ""
    @State private var isAddingSchedule = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Constants.Style.controlsSpacing) {
                ProfileRow(name: "Camera Default", profile: .defaultProfile)
                Divider()
                ForEach(profileManager.profiles, id: \.self) { profile in
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

            Divider()
                .padding(.vertical, Constants.Style.padding)

            SectionTitle(title: "Scheduler", image: Image(systemName: "clock"))
                .padding(.bottom, Constants.Style.padding)

            VStack(spacing: Constants.Style.controlsSpacing) {
                ForEach(scheduleManager.schedules) { schedule in
                    ScheduleRow(schedule: schedule)
                }
            }
            .padding(.bottom, Constants.Style.topSpacing)

            if isAddingSchedule {
                AddScheduleView(isPresented: $isAddingSchedule)
            } else {
                Button("Add Schedule") {
                    isAddingSchedule = true
                }
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

//
//  ProfileManager.swift
//  CameraController
//
//  Created by Itay Brenner on 8/7/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published private(set) var profiles: [Profile] = []

    private init() {
        if let savedProfiles = UserDefaults.standard.object(forKey: "profiles") as? Data {
            let decoder = JSONDecoder()
            if let profiles = try? decoder.decode([Profile].self, from: savedProfiles) {
                self.profiles = profiles
            }
        }
    }

    func saveProfile(_ name: String, _ settings: DeviceSettings) {
        let newProfile = Profile(name: name, settings: settings)
        profiles.append(newProfile)
        saveProfiles()
    }

    func deleteProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(of: profile) else {
            return
        }

        profiles.remove(at: index)
        saveProfiles()

        // Remove any schedules that referenced the now-deleted profile.
        for schedule in ScheduleManager.shared.schedules where schedule.profileName == profile.name {
            ScheduleManager.shared.deleteSchedule(schedule)
        }
    }

    func updateProfile(_ profile: Profile, _ settings: DeviceSettings) {
        guard let index = profiles.firstIndex(of: profile) else {
            return
        }

        let newProfile = Profile(name: profile.name, settings: settings)
        profiles[index] = newProfile
        saveProfiles()
    }

    private func saveProfiles() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: "profiles")
        }
    }
}

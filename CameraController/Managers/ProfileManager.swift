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
            do {
                let profiles = try decoder.decode([Profile].self, from: savedProfiles)
                self.profiles = profiles
            } catch {
                print("Unable to decode saved profiles: \(error)")
            }
        }
    }

    func saveProfile(_ name: String, _ settings: DeviceSettings) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("Profile name cannot be empty")
            return
        }

        let newProfile = Profile(name: trimmedName, settings: settings)
        profiles.append(newProfile)
        saveProfiles()
    }

    func deleteProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(of: profile) else {
            return
        }

        profiles.remove(at: index)
        saveProfiles()
    }

    func updateProfile(_ profile: Profile, _ settings: DeviceSettings) {
        guard let index = profiles.firstIndex(of: profile) else {
            return
        }

        let newProfile = Profile(id: profile.id,
                                 name: profile.name,
                                 isDefault: profile.isDefault,
                                 settings: settings)
        profiles[index] = newProfile
        saveProfiles()
    }

    private func saveProfiles() {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(profiles)
            UserDefaults.standard.set(encoded, forKey: "profiles")
        } catch {
            print("Unable to encode profiles: \(error)")
        }
    }
}

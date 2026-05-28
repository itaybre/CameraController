//
//  Profile.swift
//  CameraController
//
//  Created by Itay Brenner on 8/7/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

struct Profile: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let isDefault: Bool
    let settings: DeviceSettings?

    init(name: String, settings: DeviceSettings) {
        self.id = UUID()
        self.name = name
        self.settings = settings
        self.isDefault = false
    }

    init() {
        self.id = UUID()
        self.name = "Camera Default"
        self.settings = nil
        self.isDefault = true
    }

    init(id: UUID, name: String, isDefault: Bool, settings: DeviceSettings?) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.settings = settings
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDefault
        case settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
        self.settings = try container.decodeIfPresent(DeviceSettings.self, forKey: .settings)
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

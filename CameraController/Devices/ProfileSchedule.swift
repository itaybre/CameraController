//
//  ProfileSchedule.swift
//  CameraController
//
//  Created by Copilot on 25/7/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation

/// A recurring rule that applies a `Profile` to the currently selected camera
/// at a given time, on one or more days of the week.
struct ProfileSchedule: Codable, Identifiable, Hashable {
    let id: UUID
    var profileName: String
    var hour: Int
    var minute: Int
    /// Days of the week the schedule fires on, using `Calendar`'s weekday
    /// numbering (1 = Sunday ... 7 = Saturday).
    var weekdays: Set<Int>
    var isEnabled: Bool

    init(profileName: String, hour: Int, minute: Int, weekdays: Set<Int>, isEnabled: Bool = true) {
        self.id = UUID()
        self.profileName = profileName
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.isEnabled = isEnabled
    }
}

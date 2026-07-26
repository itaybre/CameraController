//
//  ScheduleManager.swift
//  CameraController
//
//  Created by Copilot on 25/7/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation
import Combine

/// Persists `ProfileSchedule`s and periodically checks whether one of them
/// should be applied to the currently selected camera.
final class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    @Published private(set) var schedules: [ProfileSchedule] = []

    private var timer: Timer?
    // Prevents firing the same schedule multiple times within the same minute.
    private var lastFiredKey: String?

    private init() {
        if let savedSchedules = UserDefaults.standard.object(forKey: "profileSchedules") as? Data {
            let decoder = JSONDecoder()
            if let schedules = try? decoder.decode([ProfileSchedule].self, from: savedSchedules) {
                self.schedules = schedules
            }
        }
    }

    func addSchedule(_ schedule: ProfileSchedule) {
        schedules.append(schedule)
        saveSchedules()
    }

    func deleteSchedule(_ schedule: ProfileSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()
    }

    func setEnabled(_ schedule: ProfileSchedule, isEnabled: Bool) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
            return
        }

        schedules[index].isEnabled = isEnabled
        saveSchedules()
    }

    private func saveSchedules() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "profileSchedules")
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        stopMonitoring()

        checkSchedules()
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkSchedules() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: Date())

        guard let hour = components.hour, let minute = components.minute, let weekday = components.weekday else {
            return
        }

        let minuteKey = "\(weekday)-\(hour)-\(minute)"
        guard minuteKey != lastFiredKey else {
            return
        }

        guard let schedule = schedules.first(where: {
            $0.isEnabled && $0.hour == hour && $0.minute == minute && $0.weekdays.contains(weekday)
        }) else {
            return
        }

        lastFiredKey = minuteKey
        apply(schedule)
    }

    private func apply(_ schedule: ProfileSchedule) {
        guard let controller = DevicesManager.shared.selectedDevice?.controller else {
            return
        }

        if schedule.profileName == Profile().name {
            controller.resetDefault()
            return
        }

        guard let profile = ProfileManager.shared.profiles.first(where: { $0.name == schedule.profileName }),
              let settings = profile.settings else {
            return
        }

        controller.set(settings)
        DevicesManager.shared.selectedDevice?.writeValuesToDevice()
    }
}

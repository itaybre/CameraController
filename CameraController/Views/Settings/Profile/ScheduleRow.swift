//
//  ScheduleRow.swift
//  CameraController
//
//  Created by Copilot on 25/7/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import SwiftUI

struct ScheduleRow: View {
    @ObservedObject var scheduleManager = ScheduleManager.shared
    let schedule: ProfileSchedule
    @State private var showIcons = false

    private static let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        SectionView {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.profileName)
                        .fontWeight(.bold)
                    Text("\(timeString) · \(daysString)")
                        .font(.caption)
                        .opacity(0.7)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { scheduleManager.setEnabled(schedule, isEnabled: $0) }
                ))

                if showIcons {
                    Button {
                        withAnimation {
                            scheduleManager.deleteSchedule(schedule)
                        }
                    } label: {
                        Image(systemName: "trash")
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

    private var timeString: String {
        String(format: "%02d:%02d", schedule.hour, schedule.minute)
    }

    private var daysString: String {
        if schedule.weekdays.count == 7 {
            return "Every day"
        }
        return schedule.weekdays.sorted().map { Self.weekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }
}

#if DEBUG
struct ScheduleRow_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleRow(schedule: ProfileSchedule(profileName: "Meeting",
                                              hour: 9,
                                              minute: 0,
                                              weekdays: [2, 3, 4, 5, 6]))
        .frame(width: 320)
        .padding()
    }
}
#endif

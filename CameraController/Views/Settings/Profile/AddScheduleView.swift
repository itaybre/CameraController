//
//  AddScheduleView.swift
//  CameraController
//
//  Created by Copilot on 25/7/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import SwiftUI

struct AddScheduleView: View {
    @ObservedObject var scheduleManager = ScheduleManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @Binding var isPresented: Bool

    @State private var selectedProfileName = Profile().name
    @State private var time = Date()
    @State private var selectedWeekdays: Set<Int> = Set(1...7)

    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        SectionView {
            SectionTitle(title: "New Schedule", image: Image(systemName: "clock"))

            Picker("Profile", selection: $selectedProfileName) {
                Text(Profile().name).tag(Profile().name)
                ForEach(profileManager.profiles, id: \.self) { profile in
                    Text(profile.name).tag(profile.name)
                }
            }

            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { weekday in
                    Button {
                        toggle(weekday)
                    } label: {
                        Text(Self.weekdaySymbols[weekday - 1])
                            .frame(width: 24, height: 24)
                            .background(
                                Circle().fill(
                                    selectedWeekdays.contains(weekday)
                                        ? Constants.Colors.accentColor
                                        : Constants.Colors.sectionBackground
                                )
                            )
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }

                Spacer()

                Button("Add Schedule") {
                    addSchedule()
                }
                .disabled(selectedWeekdays.isEmpty)
            }
        }
    }

    private func toggle(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    private func addSchedule() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = components.hour, let minute = components.minute else {
            return
        }

        let schedule = ProfileSchedule(profileName: selectedProfileName,
                                       hour: hour,
                                       minute: minute,
                                       weekdays: selectedWeekdays)
        withAnimation {
            scheduleManager.addSchedule(schedule)
            isPresented = false
        }
    }
}

#if DEBUG
struct AddScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        AddScheduleView(isPresented: .constant(true))
            .frame(width: 320)
            .padding()
    }
}
#endif

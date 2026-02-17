//
//  CropStateManager.swift
//  CameraController
//
//  Created by dweebzxx on 17/2/26.
//  Copyright © 2026 dweebzxx. All rights reserved.
//

import Foundation
import Combine

final class CropStateManager: ObservableObject {
    static let shared = CropStateManager()

    private var states: [String: CropState] = [:]
    private let storageKey = "cropStates"

    private init() {
        loadAllStoredStates()
    }

    func cropState(for deviceID: String) -> CropState {
        if let existing = states[deviceID] {
            return existing
        }

        let newState = CropState(deviceID: deviceID)

        // Try to load stored state
        if let stored = loadStoredState(for: deviceID) {
            newState.apply(stored)
        }

        states[deviceID] = newState
        return newState
    }

    func save(_ state: CropState) {
        states[state.deviceID] = state

        var allStates: [String: StorableCropState] = [:]

        // Load existing states from UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: StorableCropState].self, from: data) {
            allStates = decoded
        }

        // Update with current state
        allStates[state.deviceID] = state.toStorable()

        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(allStates) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func remove(for deviceID: String) {
        states.removeValue(forKey: deviceID)

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var allStates = try? JSONDecoder().decode([String: StorableCropState].self, from: data) else {
            return
        }

        allStates.removeValue(forKey: deviceID)

        if let encoded = try? JSONEncoder().encode(allStates) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadStoredState(for deviceID: String) -> StorableCropState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let allStates = try? JSONDecoder().decode([String: StorableCropState].self, from: data) else {
            return nil
        }

        return allStates[deviceID]
    }

    private func loadAllStoredStates() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let allStates = try? JSONDecoder().decode([String: StorableCropState].self, from: data) else {
            return
        }

        // Pre-populate states dictionary
        for (deviceID, storedState) in allStates {
            let state = CropState(deviceID: deviceID)
            state.apply(storedState)
            states[deviceID] = state
        }
    }
}

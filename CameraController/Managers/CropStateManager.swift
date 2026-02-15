//
//  CropStateManager.swift
//  CameraController
//
//  Created by Itay Brenner on 2/15/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation
import Combine

/// Singleton manager for per-camera crop state persistence
final class CropStateManager {
    static let shared = CropStateManager()
    
    private let storageKey = "cropStates"
    private var states: [String: CropState] = [:]
    
    private init() {}
    
    /// Get or create crop state for a device
    func cropState(for deviceID: String) -> CropState {
        if let existing = states[deviceID] {
            return existing
        }
        
        let newState = CropState(deviceID: deviceID)
        
        // Try to restore from disk
        if let stored = loadStoredState(for: deviceID) {
            newState.apply(stored)
        }
        
        states[deviceID] = newState
        return newState
    }
    
    /// Save crop state to persistent storage
    func save(_ state: CropState) {
        var allStored = loadAllStoredStates()
        allStored[state.deviceID] = state.toStorable()
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(allStored) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    /// Remove persisted crop state for a device
    func remove(for deviceID: String) {
        var allStored = loadAllStoredStates()
        allStored.removeValue(forKey: deviceID)
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(allStored) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        
        states.removeValue(forKey: deviceID)
    }
    
    // MARK: - Private Helpers
    
    private func loadStoredState(for deviceID: String) -> StorableCropState? {
        let allStored = loadAllStoredStates()
        return allStored[deviceID]
    }
    
    private func loadAllStoredStates() -> [String: StorableCropState] {
        guard let data = UserDefaults.standard.object(forKey: storageKey) as? Data else {
            return [:]
        }
        
        let decoder = JSONDecoder()
        if let states = try? decoder.decode([String: StorableCropState].self, from: data) {
            return states
        }
        
        return [:]
    }
}

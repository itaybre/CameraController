//
//  UserSettings.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Combine
import ServiceManagement

final class UserSettings: ObservableObject {
    static let shared = UserSettings()
    private static let loginHelperIdentifier = "com.itaysoft.CameraController.Helper"

    @Published var openAtLogin: Bool {
        didSet {
            if setOpenAtLogin(openAtLogin) {
                UserDefaults.standard.set(openAtLogin, forKey: "login")
            }
        }
    }

    @Published var readRate: RefreshSettingsRate {
        didSet {
            UserDefaults.standard.set(readRate.rawValue, forKey: "readRate")
        }
    }

    @Published var writeRate: RefreshSettingsRate {
        didSet {
            UserDefaults.standard.set(writeRate.rawValue, forKey: "writeRate")
        }
    }

    @Published var lastSelectedDevice: String? {
        didSet {
            UserDefaults.standard.set(lastSelectedDevice, forKey: "lastDevice")
        }
    }

    var hideCameraPreview: Bool {
        cameraPreviewSize == .disabled
    }

    @Published var cameraPreviewSize: PreviewSizeSettings {
        didSet {
            UserDefaults.standard.set(cameraPreviewSize.rawValue, forKey: "cameraPreviewSize")
        }
    }

    @Published var checkForUpdatesOnStartup: Bool {
        didSet {
            UserDefaults.standard.set(checkForUpdatesOnStartup, forKey: "checkForUpdatesOnStartup")
        }
    }

    @Published var mirrorPreview: Bool {
        didSet {
            UserDefaults.standard.set(mirrorPreview, forKey: "mirrorPreview")
        }
    }

    private init() {
        openAtLogin = UserDefaults.standard.bool(forKey: "login")
        readRate = RefreshSettingsRate(rawValue: UserDefaults.standard.double(forKey: "readRate")) ?? .disabled
        writeRate = RefreshSettingsRate(rawValue: UserDefaults.standard.double(forKey: "writeRate")) ?? .disabled
        lastSelectedDevice = UserDefaults.standard.string(forKey: "lastDevice")
        cameraPreviewSize = PreviewSizeSettings(
            rawValue: UserDefaults.standard.double(forKey: "cameraPreviewSize")
        ) ?? .small
        checkForUpdatesOnStartup = UserDefaults.standard.bool(forKey: "checkForUpdatesOnStartup")
        mirrorPreview = UserDefaults.standard.bool(forKey: "mirrorPreview")
    }

    private func setOpenAtLogin(_ isEnabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: Self.loginHelperIdentifier)
            do {
                if isEnabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
                return true
            } catch {
                print("Unable to update login item: \(error)")
                return false
            }
        } else {
            let success = SMLoginItemSetEnabled(Self.loginHelperIdentifier as CFString, isEnabled)
            if !success {
                print("Unable to update login item")
            }
            return success
        }
    }
}

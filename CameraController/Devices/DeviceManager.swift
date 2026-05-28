//
//  DeviceManager.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Combine
import Foundation
import AVFoundation

final class DevicesManager: ObservableObject {
    static let shared = DevicesManager()

    private let deviceMonitor = DeviceMonitor()

    @Published var devices: [CaptureDevice] = []

    @Published var selectedDevice: CaptureDevice? {
        willSet {
            if newValue != nil && selectedDevice != newValue {
                UserSettings.shared.lastSelectedDevice = newValue?.avDevice?.uniqueID
            }
            deviceMonitor.updateDevice(newValue)
        }
    }

    private init() {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
                                                                mediaType: nil,
                                                                position: .unspecified)
        devices = session.devices.map({ (device) -> CaptureDevice in
            CaptureDevice(avDevice: device)
        })

        if let deviceId = UserSettings.shared.lastSelectedDevice {
            selectedDevice = devices.first { (device) -> Bool in
                device.avDevice?.uniqueID == deviceId
            }
        }
    }

    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceAdded(notif:)),
                                               name: NSNotification.Name.AVCaptureDeviceWasConnected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRemoved(notif:)),
                                               name: NSNotification.Name.AVCaptureDeviceWasDisconnected,
                                               object: nil)
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVCaptureDeviceWasConnected,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVCaptureDeviceWasDisconnected,
                                                  object: nil)
    }

    @objc
    func deviceAdded(notif: NSNotification) {
        guard let device = notif.object as? AVCaptureDevice else {
            return
        }

        devices.append(CaptureDevice(avDevice: device))
        NotificationCenter.default.post(name: .devicesUpdated, object: nil)
    }

    @objc
    func deviceRemoved(notif: NSNotification) {
        guard let device = notif.object as? AVCaptureDevice else {
            return
        }

        guard let index = devices.firstIndex(where: { (captureDevice) -> Bool in
            captureDevice.avDevice == device
        }) else {
            return
        }

        devices.remove(at: index)

        if device.uniqueID == selectedDevice?.avDevice?.uniqueID {
            selectedDevice = nil
        }
        NotificationCenter.default.post(name: .devicesUpdated, object: nil)
    }
}

//
//  StatusBarManager.swift
//  CameraController
//
//  Created by Itay Brenner on 25/1/22.
//  Copyright © 2022 Itaysoft. All rights reserved.
//

import Foundation
import Cocoa

class StatusBarManager {
    var statusBarItem: NSStatusItem!

    init() {
        // Fix for SwiftUI Previews adding Statusbar Items constantly
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return
        }
        #endif

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusBarItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "camera.fill",
                               accessibilityDescription: "Camera Controller")
        button.imageScaling = NSImageScaling.scaleProportionallyDown
        button.target = self
        button.action = #selector(showCustomView)
    }

    @objc
    func showCustomView() {
        print("🔵 [StatusBarManager] showCustomView() called")
        guard let button = statusBarItem?.button else {
            print("🔴 [StatusBarManager] ERROR: statusBarItem.button is nil")
            return
        }
        print("🔵 [StatusBarManager] button exists, calling WindowManager")
        WindowManager.shared.toggleShowWindow(from: button)
    }
}

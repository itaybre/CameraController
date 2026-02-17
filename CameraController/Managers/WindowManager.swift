//
//  WindowManager.swift
//  CameraController
//
//  Created by Itay Brenner on 25/1/22.
//  Copyright © 2022 Itaysoft. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI

class WindowManager: NSObject {
    static let shared = WindowManager()

    private var popover: NSPopover?
    private var isShowing: Bool = false

    func toggleShowWindow(from button: NSButton) {
        print("🔵 [WindowManager] toggleShowWindow called, isShowing: \(isShowing)")
        if isShowing {
            closeWindow()
        } else {
            showWindow(from: button)
        }
    }

    func showWindow(from button: NSButton) {
        print("🔵 [WindowManager] showWindow() called")
        NotificationCenter.default.post(name: .windowOpen, object: nil)

        let contentView = ContentView()
        print("🔵 [WindowManager] ContentView created")

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: contentView)
        popover?.contentSize.width = UserSettings.shared.cameraPreviewSize.getWidth()
        popover?.contentSize.height = 100
        popover?.behavior = .transient
        popover?.delegate = self

        print("🔵 [WindowManager] NSPopover configured, about to show...")
        print("🔵 [WindowManager]   - button.bounds: \(button.bounds)")
        print("🔵 [WindowManager]   - popover.contentSize: \(popover?.contentSize ?? .zero)")

        DispatchQueue.main.async { [weak self] in
            print("🔵 [WindowManager] Inside main.async before show")
            self?.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            print("🔵 [WindowManager] popover.show() called")
            self?.popover?.contentViewController?.view.window?.makeKey()
            print("🔵 [WindowManager] makeKey() called, isShowing = true")
        }

        isShowing = true
        print("🔵 [WindowManager] showWindow() complete")
    }

    func closeWindow() {
        print("🔵 [WindowManager] closeWindow() called")
        isShowing = false

        popover?.performClose(nil)
    }
}

extension WindowManager: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    func popoverWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .windowClose, object: nil)
        isShowing = false
    }

    func popoverDidDetach(_ popover: NSPopover) {
        // Disable dragging, only dragging with the preview is allowed
        popover.contentViewController?.view.window?.isMovableByWindowBackground = false
    }
}

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
        if isShowing {
            closeWindow()
        } else {
            showWindow(from: button)
        }
    }

    func showWindow(from button: NSButton) {
        NotificationCenter.default.post(name: .windowOpen, object: nil)

        let contentView = ContentView()

        let hostingController = NSHostingController(rootView: contentView)
        if #available(macOS 13.0, *) {
            // Keeps NSPopover's size in sync with SwiftUI's ideal content size,
            // so the popover grows/shrinks as tabs like Basic/Advanced are expanded.
            hostingController.sizingOptions = [.preferredContentSize]
        }

        popover = NSPopover()
        popover?.contentViewController = hostingController
        popover?.contentSize.width = UserSettings.shared.cameraPreviewSize.getWidth()
        popover?.contentSize.height = 100
        popover?.behavior = .transient
        popover?.delegate = self
        DispatchQueue.main.async { [weak self] in
            self?.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            self?.popover?.contentViewController?.view.window?.makeKey()
        }

        isShowing = true
    }

    func closeWindow() {
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

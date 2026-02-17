//
//  CameraPreview.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    @Binding var captureDevice: CaptureDevice?
    @ObservedObject var cropState: CropState

    func makeNSView(context: Context) -> CameraPreviewInternal {
        let view = CameraPreviewInternal(frame: .zero, device: captureDevice?.avDevice)
        view.cropState = cropState
        return view
    }

    func updateNSView(_ nsView: CameraPreviewInternal, context: NSViewRepresentableContext<CameraPreview>) {
        nsView.updateCamera(captureDevice?.avDevice)
        nsView.cropState = cropState
    }

    static func dismantleNSView(_ nsView: CameraPreviewInternal, coordinator: ()) {
        nsView.stopRunning()
    }
}

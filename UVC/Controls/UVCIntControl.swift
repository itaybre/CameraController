//
//  UVCIntControl.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

public final class UVCIntControl: UVCControl {
    public var minimum: Int = 0
    public var maximum: Int = 0
    public var defaultValue: Int = 0
    public var resolution: Int = 0

    public var current: Int {
        get {
            return _current
        }
        set {
            if setData(value: newValue, length: uvcSize) {
                _current = newValue
            }
        }
    }

    private var _current: Int = 0

    override init(_ interface: USBInterfacePointer, _ uvcSize: Int,
                  _ uvcSelector: Selector, _ uvcUnit: Int, _ uvcInterface: Int) {
        super.init(interface, uvcSize, uvcSelector, uvcUnit, uvcInterface)
        configure()
    }

    private func configure() {
        updateIsCapable()

        if isCapable {
            updateMinimum()
            updateDefault()
            updateMaximum()
            updateResolution()
            _current = getCurrent()

            if minimum > maximum {
                minimum = 0
            }

            isCapable = minimum != maximum
        }
    }

    public func getCurrent() -> Int {
        _current = getDataFor(type: .getCurrent, length: uvcSize)
        return _current
    }

    func updateMinimum() {
        minimum = getDataFor(type: .getMinimum, length: uvcSize)
    }

    func updateMaximum() {
        maximum = getDataFor(type: .getMaximum, length: uvcSize)
    }

    func updateDefault() {
        defaultValue = getDataFor(type: .getDefault, length: uvcSize)
    }

    func updateResolution() {
        resolution = getDataFor(type: .getRessolution, length: uvcSize)
    }
}

//
//  UVCMultipleIntControl.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

public final class UVCMultipleIntControl: UVCControl {
    public var minimum1: Int = 0
    public var minimum2: Int = 0
    public var maximum1: Int = 0
    public var maximum2: Int = 0
    public var defaultValue1: Int = 0
    public var defaultValue2: Int = 0
    public var resolution1: Int = 0
    public var resolution2: Int = 0

    public var current1: Int {
        get {
            return _current1
        }
        set {
            if set1(newValue) {
                _current1 = newValue
            }
        }
    }

    public var current2: Int {
        get {
            return _current2
        }
        set {
            if set2(newValue) {
                _current2 = newValue
            }
        }
    }

    private var _current1: Int = 0
    private var _current2: Int = 0

    override init(_ interface: USBInterfacePointer, _ uvcSize: Int,
                  _ uvcSelector: Selector, _ uvcUnit: Int, _ uvcInterface: Int) {
        super.init(interface, uvcSize, uvcSelector, uvcUnit, uvcInterface)
        configure()
    }

    private func set1(_ val1: Int) -> Bool {
        let newValue = ((val1 * 3600) << 32) + (_current2 * 3600)
        return setData(value: newValue, length: uvcSize)
    }

    private func set2(_ val2: Int) -> Bool {
        let newValue = ((_current1 * 3600) << 32) + (val2 * 3600)
        return setData(value: newValue, length: uvcSize)
    }

    private func configure() {
        updateIsCapable()

        if isCapable {
            updateMinimum()
            updateDefault()
            updateMaximum()
            updateCurrent()
            updateResolution()
        }
    }

    func splitValue(_ value: Int) -> (Int, Int) {
        let array: [UInt8] = self.toByteArray(value: value)

        let array1: [UInt8] = Array(array.prefix(4))
        let array2: [UInt8] = array.suffix(4)

        let value1 = Int(Int32(array1).littleEndian)/3600
        let value2 = Int(Int32(array2).littleEndian)/3600

        return (value1, value2)
    }

    func toByteArray( value: Int) -> [UInt8] {
        var msgLength = [UInt8](repeating: 0, count: 8)

        for index in 0...7 {
            msgLength[index] = UInt8((value >> Int((7 - index) * 8)) & 0x0000FF)
        }
        return msgLength
    }

    func updateCurrent() {
        let currentValue = getDataFor(type: .getCurrent, length: uvcSize)
        let splitted = splitValue(currentValue)
        _current1 = splitted.0
        _current2 = splitted.1
    }

    func updateMinimum() {
        let minimum = getDataFor(type: .getMinimum, length: uvcSize)
        let splitted = splitValue(minimum)
        minimum1 = splitted.0
        minimum2 = splitted.1
    }

    func updateMaximum() {
        let maximum = getDataFor(type: .getMaximum, length: uvcSize)
        let splitted = splitValue(maximum)
        maximum1 = splitted.0
        maximum2 = splitted.1
    }

    func updateDefault() {
        let defaultValue = getDataFor(type: .getDefault, length: uvcSize)
        let splitted = splitValue(defaultValue)
        defaultValue1 = splitted.0
        defaultValue2 = splitted.1
    }

    func updateResolution() {
        let resolution = getDataFor(type: .getRessolution, length: uvcSize)
        let splitted = splitValue(resolution)
        resolution1 = splitted.0
        resolution2 = splitted.1
    }
}

public extension SignedInteger {
    init(_ bytes: [UInt8]) {
        precondition(bytes.count <= MemoryLayout<Self>.size)

        var value: Int32 = 0

        for byte in bytes {
            value <<= 8
            value |= Int32(byte)
        }

        self.init(value)
    }
}

//
//  UVCErrors.swift
//  CameraController
//
//  Created by Itay Brenner on 21/6/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import Foundation

enum UVCError: Error {
    case requestError
    case invalidUnitId
    case invalidInterfaceId
    case invalidRequestLength
    case noMatchingDevice
    case pluginInterfaceCreationFailed
    case interfaceIteratorCreationFailed
    case deviceInterfaceUnavailable
    case controlInterfaceUnavailable
    case configurationDescriptorUnavailable
}

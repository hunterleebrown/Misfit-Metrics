//
//  BluetoothDeviceMemory.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import Foundation
import CoreBluetooth

/// Manages persistent storage of previously connected Bluetooth devices
class BluetoothDeviceMemory {
    
    enum DeviceType: String {
        case heartRate = "lastHeartRateDevice"
        case power = "lastPowerDevice"
    }
    
    struct SavedDevice: Codable {
        let identifier: String
        let name: String?
        let lastConnected: Date
    }
    
    private let defaults = UserDefaults.standard
    
    /// Save a device to memory
    func save(device: CBPeripheral, type: DeviceType) {
        let savedDevice = SavedDevice(
            identifier: device.identifier.uuidString,
            name: device.name,
            lastConnected: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(savedDevice) {
            defaults.set(encoded, forKey: type.rawValue)
        }
    }
    
    /// Retrieve the last connected device
    func getLastDevice(type: DeviceType) -> SavedDevice? {
        guard let data = defaults.data(forKey: type.rawValue),
              let device = try? JSONDecoder().decode(SavedDevice.self, from: data) else {
            return nil
        }
        return device
    }
    
    /// Clear the saved device
    func clearDevice(type: DeviceType) {
        defaults.removeObject(forKey: type.rawValue)
    }
    
    /// Check if a peripheral matches the saved device
    func matches(_ peripheral: CBPeripheral, type: DeviceType) -> Bool {
        guard let saved = getLastDevice(type: type) else { return false }
        return peripheral.identifier.uuidString == saved.identifier
    }
}

//
//  PowerMonitor.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import CoreBluetooth
import SwiftUI

@Observable
class PowerMonitor: NSObject {
    // MARK: - Published Properties
    var instantaneousPower: Double = 0.0
    var threeSecondPower: Double = 0.0
    var cadence: Double = 0.0
    var isConnected: Bool = false
    var isScanning: Bool = false
    var availableDevices: [CBPeripheral] = []
    var statusMessage: String = "Not connected"
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var powerPeripheral: CBPeripheral?
    
    // Standard Bluetooth Cycling Power Service and Characteristic UUIDs
    private let cyclingPowerServiceUUID = CBUUID(string: "1818")
    private let cyclingPowerMeasurementCharacteristicUUID = CBUUID(string: "2A63")
    
    // For calculating 3-second average
    private var powerReadings: [Double] = []
    private let maxReadingsFor3Seconds = 12 // Assuming ~4 Hz update rate
    
    // For calculating cadence from crank revolutions
    private var lastCrankRevolutions: UInt16?
    private var lastCrankEventTime: UInt16?
    private var cadenceTimeout: Date?
    private let cadenceTimeoutDuration: TimeInterval = 3.0 // Reset cadence to 0 after 3 seconds of no data
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for power meters
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth not available"
            return
        }
        
        availableDevices.removeAll()
        isScanning = true
        statusMessage = "Scanning for power meters..."
        
        // Scan for devices advertising the Cycling Power Service
        centralManager.scanForPeripherals(
            withServices: [cyclingPowerServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if !isConnected {
            statusMessage = "Scan stopped"
        }
    }
    
    /// Connect to a specific peripheral
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        statusMessage = "Connecting to \(peripheral.name ?? "device")..."
        powerPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from current device
    func disconnect() {
        if let peripheral = powerPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        instantaneousPower = 0.0
        threeSecondPower = 0.0
        cadence = 0.0
        powerReadings.removeAll()
        lastCrankRevolutions = nil
        lastCrankEventTime = nil
        cadenceTimeout = nil
        isConnected = false
        statusMessage = "Disconnected"
    }
    
    // MARK: - Private Methods
    
    private func addPowerReading(_ power: Double) {
        powerReadings.append(power)
        
        // Keep only the last N readings for 3-second average
        if powerReadings.count > maxReadingsFor3Seconds {
            powerReadings.removeFirst()
        }
        
        // Calculate 3-second average
        if !powerReadings.isEmpty {
            threeSecondPower = powerReadings.reduce(0, +) / Double(powerReadings.count)
        }
    }
    
    /// Check if cadence should be reset to 0 due to timeout
    func checkCadenceTimeout() {
        guard let timeout = cadenceTimeout else { return }
        if Date() > timeout {
            cadence = 0.0
            cadenceTimeout = nil
            lastCrankRevolutions = nil
            lastCrankEventTime = nil
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension PowerMonitor: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth ready"
        case .poweredOff:
            statusMessage = "Bluetooth is powered off"
        case .unauthorized:
            statusMessage = "Bluetooth permission denied"
        case .unsupported:
            statusMessage = "Bluetooth not supported"
        case .resetting:
            statusMessage = "Bluetooth resetting..."
        case .unknown:
            statusMessage = "Bluetooth state unknown"
        @unknown default:
            statusMessage = "Unknown Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Add device to list if not already present
        if !availableDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            availableDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusMessage = "Connected to \(peripheral.name ?? "device")"
        
        peripheral.delegate = self
        peripheral.discoverServices([cyclingPowerServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        instantaneousPower = 0.0
        threeSecondPower = 0.0
        cadence = 0.0
        powerReadings.removeAll()
        lastCrankRevolutions = nil
        lastCrankEventTime = nil
        cadenceTimeout = nil
        
        if let error = error {
            statusMessage = "Disconnected with error: \(error.localizedDescription)"
        } else {
            statusMessage = "Disconnected"
        }
    }
}

// MARK: - CBPeripheralDelegate
extension PowerMonitor: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            statusMessage = "Error discovering services: \(error!.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == cyclingPowerServiceUUID {
                peripheral.discoverCharacteristics([cyclingPowerMeasurementCharacteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            statusMessage = "Error discovering characteristics: \(error!.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == cyclingPowerMeasurementCharacteristicUUID {
                // Subscribe to power notifications
                peripheral.setNotifyValue(true, for: characteristic)
                statusMessage = "Receiving power data"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error updating value: \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == cyclingPowerMeasurementCharacteristicUUID {
            let (power, cadenceValue) = parsePowerData(from: characteristic)
            instantaneousPower = power
            addPowerReading(power)
            
            if let cadenceValue = cadenceValue {
                cadence = cadenceValue
                // Set timeout for cadence to go back to 0 if no updates received
                cadenceTimeout = Date().addingTimeInterval(cadenceTimeoutDuration)
            }
        }
    }
    
    // MARK: - Power Data Parsing
    
    /// Parse power and cadence values from the characteristic data
    /// According to Bluetooth Cycling Power Service specification
    /// Returns: (power: Double, cadence: Double?)
    private func parsePowerData(from characteristic: CBCharacteristic) -> (Double, Double?) {
        guard let data = characteristic.value else { return (0.0, nil) }
        
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else { return (0.0, nil) }
        
        // First 2 bytes contain flags (16-bit)
        let flags = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        
        // Bytes 2-3 contain instantaneous power (16-bit signed integer, little endian)
        let powerLow = UInt16(bytes[2])
        let powerHigh = UInt16(bytes[3])
        let powerValue = Int16(bitPattern: powerLow | (powerHigh << 8))
        
        let power = Double(max(0, powerValue)) // Negative values indicate invalid/no power
        
        // Check if Crank Revolution Data is present (bit 5)
        let crankDataPresent = (flags & 0x20) != 0
        
        var cadence: Double? = nil
        
        if crankDataPresent {
            // Calculate the offset where crank data starts
            var offset = 4 // Start after flags (2 bytes) and power (2 bytes)
            
            // Check for optional fields before crank data
            // Bit 0: Pedal Power Balance Present (1 byte)
            if (flags & 0x01) != 0 {
                offset += 1
            }
            
            // Bit 2: Accumulated Torque Present (2 bytes)
            if (flags & 0x04) != 0 {
                offset += 2
            }
            
            // Bit 4: Wheel Revolution Data Present (6 bytes)
            if (flags & 0x10) != 0 {
                offset += 6
            }
            
            // Now we should be at the crank revolution data
            // Crank Revolution Data consists of:
            // - Cumulative Crank Revolutions: 2 bytes (UInt16)
            // - Last Crank Event Time: 2 bytes (UInt16) in 1/1024 seconds
            
            if bytes.count >= offset + 4 {
                let crankRevolutions = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
                let crankEventTime = UInt16(bytes[offset + 2]) | (UInt16(bytes[offset + 3]) << 8)
                
                // Calculate cadence using the difference method
                if let lastRevs = lastCrankRevolutions, let lastTime = lastCrankEventTime {
                    // Handle rollover for UInt16
                    let revDiff = crankRevolutions >= lastRevs ? 
                        Int(crankRevolutions - lastRevs) : 
                        Int(Int(crankRevolutions) + 65536 - Int(lastRevs))
                    
                    let timeDiff = crankEventTime >= lastTime ? 
                        Int(crankEventTime - lastTime) : 
                        Int(Int(crankEventTime) + 65536 - Int(lastTime))
                    
                    // Calculate cadence in RPM
                    // timeDiff is in 1/1024 seconds, convert to minutes
                    if timeDiff > 0 {
                        let timeInMinutes = Double(timeDiff) / 1024.0 / 60.0
                        let calculatedCadence = Double(revDiff) / timeInMinutes
                        
                        // Sanity check: cadence should be between 0 and 300 RPM
                        if calculatedCadence >= 0 && calculatedCadence <= 300 {
                            cadence = calculatedCadence
                        }
                        
                        // If revDiff is 0 (no movement), set cadence to 0
                        if revDiff == 0 {
                            cadence = 0.0
                        }
                    }
                }
                
                // Store current values for next calculation
                lastCrankRevolutions = crankRevolutions
                lastCrankEventTime = crankEventTime
            }
        }
        
        return (power, cadence)
    }
}

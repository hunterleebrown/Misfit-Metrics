//
//  HeartRateMonitor.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import CoreBluetooth
import SwiftUI

@Observable
class HeartRateMonitor: NSObject {
    // MARK: - Published Properties
    var heartRate: Double = 0.0
    var isConnected: Bool = false
    var isScanning: Bool = false
    var availableDevices: [CBPeripheral] = []
    var statusMessage: String = "Not connected"
    var lastConnectedDeviceName: String? {
        deviceMemory.getLastDevice(type: .heartRate)?.name
    }
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    private let deviceMemory = BluetoothDeviceMemory()
    private var shouldAutoConnect = true
    
    // Standard Bluetooth Heart Rate Service and Characteristic UUIDs
    private let heartRateServiceUUID = CBUUID(string: "180D")
    private let heartRateMeasurementCharacteristicUUID = CBUUID(string: "2A37")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for heart rate monitors
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth not available"
            return
        }
        
        availableDevices.removeAll()
        isScanning = true
        
        if shouldAutoConnect, let lastDevice = deviceMemory.getLastDevice(type: .heartRate) {
            statusMessage = "Looking for \(lastDevice.name ?? "previous device")..."
        } else {
            statusMessage = "Scanning for devices..."
        }
        
        // Scan for devices advertising the Heart Rate Service
        centralManager.scanForPeripherals(
            withServices: [heartRateServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    /// Start scanning and auto-connect to previously used device
    func startScanningWithAutoConnect() {
        shouldAutoConnect = true
        startScanning()
    }
    
    /// Clear the remembered device
    func forgetDevice() {
        deviceMemory.clearDevice(type: .heartRate)
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
        shouldAutoConnect = false // Manual connection, disable auto-connect
        statusMessage = "Connecting to \(peripheral.name ?? "device")..."
        heartRatePeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from current device
    func disconnect() {
        if let peripheral = heartRatePeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        heartRate = 0.0
        isConnected = false
        statusMessage = "Disconnected"
    }
}

// MARK: - CBCentralManagerDelegate
extension HeartRateMonitor: CBCentralManagerDelegate {
    
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
        
        // Auto-connect to previously used device if found
        if shouldAutoConnect && deviceMemory.matches(peripheral, type: .heartRate) {
            shouldAutoConnect = false // Only try once per scan
            connect(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        statusMessage = "Connected to \(peripheral.name ?? "device")"
        
        // Save this device for future auto-connect
        deviceMemory.save(device: peripheral, type: .heartRate)
        
        peripheral.delegate = self
        peripheral.discoverServices([heartRateServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        heartRate = 0.0
        
        if let error = error {
            statusMessage = "Disconnected with error: \(error.localizedDescription)"
        } else {
            statusMessage = "Disconnected"
        }
    }
}

// MARK: - CBPeripheralDelegate
extension HeartRateMonitor: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            statusMessage = "Error discovering services: \(error!.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == heartRateServiceUUID {
                peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicUUID], for: service)
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
            if characteristic.uuid == heartRateMeasurementCharacteristicUUID {
                // Subscribe to heart rate notifications
                peripheral.setNotifyValue(true, for: characteristic)
                statusMessage = "Receiving heart rate data"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error updating value: \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == heartRateMeasurementCharacteristicUUID {
            heartRate = parseHeartRateData(from: characteristic)
        }
    }
    
    // MARK: - Heart Rate Data Parsing
    
    /// Parse heart rate value from the characteristic data
    /// According to Bluetooth Heart Rate Service specification
    private func parseHeartRateData(from characteristic: CBCharacteristic) -> Double {
        guard let data = characteristic.value else { return 0.0 }
        
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else { return 0.0 }
        
        // First byte contains flags
        let flags = bytes[0]
        
        // Bit 0 of flags indicates heart rate value format
        // 0 = UInt8, 1 = UInt16
        let heartRateValueFormat = flags & 0x01
        
        var heartRateValue: UInt16 = 0
        
        if heartRateValueFormat == 0 {
            // Heart rate is UInt8 (1 byte)
            if bytes.count >= 2 {
                heartRateValue = UInt16(bytes[1])
            }
        } else {
            // Heart rate is UInt16 (2 bytes, little endian)
            if bytes.count >= 3 {
                heartRateValue = UInt16(bytes[1]) | (UInt16(bytes[2]) << 8)
            }
        }
        
        return Double(heartRateValue)
    }
}

//
//  PowerMonitorView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI
import CoreBluetooth

struct PowerMonitorView: View {
    @Bindable var powerMonitor: PowerMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Connection Status
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(powerMonitor.isConnected ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(powerMonitor.statusMessage)
                            .font(.headline)
                    }
                    
                    if powerMonitor.isConnected {
                        VStack(spacing: 12) {
                            // Instantaneous Power
                            VStack(spacing: 4) {
                                Text("Instantaneous")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(powerMonitor.instantaneousPower)) W")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color("fairyRed"))
                            }
                            
                            // 3-Second Average Power
                            VStack(spacing: 4) {
                                Text("3-Second Average")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(powerMonitor.threeSecondPower)) W")
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color("fairyRed").opacity(0.8))
                            }
                            
                            // Cadence
                            if powerMonitor.cadence > 0 {
                                VStack(spacing: 4) {
                                    Text("Cadence")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(powerMonitor.cadence)) RPM")
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color("fairyRed").opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Last Connected Device Info
                if let lastDevice = powerMonitor.lastConnectedDeviceName, !powerMonitor.isConnected {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Text("Last connected: \(lastDevice)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            powerMonitor.forgetDevice()
                        } label: {
                            Text("Forget Device")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
                
                // Device List
                if powerMonitor.isScanning || !powerMonitor.availableDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Devices")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if powerMonitor.isScanning && powerMonitor.availableDevices.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Searching for power meters...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(powerMonitor.availableDevices, id: \.identifier) { device in
                                    Button {
                                        powerMonitor.connect(to: device)
                                    } label: {
                                        HStack {
                                            Image(systemName: "bolt.circle.fill")
                                                .foregroundStyle(Color("fairyRed"))
                                            
                                            VStack(alignment: .leading) {
                                                Text(device.name ?? "Unknown Device")
                                                    .font(.body)
                                                Text(device.identifier.uuidString.prefix(8) + "...")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if !powerMonitor.isConnected {
                    VStack(spacing: 16) {
                        Image(systemName: "bolt.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No devices found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Make sure your power meter is turned on and nearby. Spin the cranks to wake it up.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if powerMonitor.isConnected {
                        Button {
                            powerMonitor.disconnect()
                        } label: {
                            Text("Disconnect")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    } else if powerMonitor.isScanning {
                        Button {
                            powerMonitor.stopScanning()
                        } label: {
                            Text("Stop Scanning")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    } else {
                        Button {
                            powerMonitor.startScanningWithAutoConnect()
                        } label: {
                            Text(powerMonitor.lastConnectedDeviceName != nil ? "Connect to Last Device" : "Scan for Devices")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("fairyRed"))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Power Meter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PowerMonitorView(powerMonitor: PowerMonitor())
}

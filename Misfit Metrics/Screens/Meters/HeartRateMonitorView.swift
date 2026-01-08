//
//  HeartRateMonitorView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI
import CoreBluetooth

struct HeartRateMonitorView: View {
    @Bindable var heartRateMonitor: HeartRateMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Connection Status
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(heartRateMonitor.isConnected ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(heartRateMonitor.statusMessage)
                            .font(.headline)
                    }
                    
                    if heartRateMonitor.isConnected {
                        Text("❤️ \(Int(heartRateMonitor.heartRate)) BPM")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("fairyRed"))
                    }
                }
                .padding()
                
                Divider()
                
                // Device List
                if heartRateMonitor.isScanning || !heartRateMonitor.availableDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Devices")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if heartRateMonitor.isScanning && heartRateMonitor.availableDevices.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Searching for heart rate monitors...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(heartRateMonitor.availableDevices, id: \.identifier) { device in
                                    Button {
                                        heartRateMonitor.connect(to: device)
                                    } label: {
                                        HStack {
                                            Image(systemName: "heart.circle.fill")
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
                } else if !heartRateMonitor.isConnected {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No devices found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Make sure your heart rate monitor is turned on and nearby.")
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
                    if heartRateMonitor.isConnected {
                        Button {
                            heartRateMonitor.disconnect()
                        } label: {
                            Text("Disconnect")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    } else if heartRateMonitor.isScanning {
                        Button {
                            heartRateMonitor.stopScanning()
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
                            heartRateMonitor.startScanning()
                        } label: {
                            Text("Scan for Devices")
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
            .navigationTitle("Heart Rate Monitor")
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
    HeartRateMonitorView(heartRateMonitor: HeartRateMonitor())
}

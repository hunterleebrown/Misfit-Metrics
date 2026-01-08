//
//  SettingsView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var heartRateMonitor: HeartRateMonitor
    @Bindable var powerMonitor: PowerMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        HeartRateMonitorView(heartRateMonitor: heartRateMonitor)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .foregroundStyle(heartRateMonitor.isConnected ? Color.green : Color("fairyRed"))
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Heart Rate Monitor")
                                    .font(.body)
                                
                                if heartRateMonitor.isConnected {
                                    Text("Connected • \(Int(heartRateMonitor.heartRate)) BPM")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let lastDevice = heartRateMonitor.lastConnectedDeviceName {
                                    Text("Last: \(lastDevice)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                    NavigationLink {
                        PowerMonitorView(powerMonitor: powerMonitor)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundStyle(powerMonitor.isConnected ? Color.green : Color("fairyRed"))
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Power Meter")
                                    .font(.body)
                                
                                if powerMonitor.isConnected {
                                    Text("Connected • \(Int(powerMonitor.threeSecondPower)) W")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let lastDevice = powerMonitor.lastConnectedDeviceName {
                                    Text("Last: \(lastDevice)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("Sensors")
                }
            }
            .navigationTitle("Settings")
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
    SettingsView(
        heartRateMonitor: HeartRateMonitor(),
        powerMonitor: PowerMonitor()
    )
}

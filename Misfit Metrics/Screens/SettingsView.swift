//
//  SettingsView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var dashboardViewModel: Dashboard.ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Picker("Background Style", selection: $dashboardViewModel.backgroundLook) {
                        Text("Bicycle").tag(Dashboard.BackgroundLook.bike)
                        Text("Rainbow").tag(Dashboard.BackgroundLook.rainbow)
                        Text("Earth").tag(Dashboard.BackgroundLook.earth)
                        Text("Plain").tag(Dashboard.BackgroundLook.plain)
                    }
                } header: {
                    Text("Dashboard Background")
                }
                
                Section {
                    NavigationLink {
                        HeartRateMonitorView(heartRateMonitor: dashboardViewModel.heartRateMonitor)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.circle.fill")
                                .foregroundStyle(dashboardViewModel.heartRateMonitor.isConnected ? Color.green : Color("fairyRed"))
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Heart Rate Monitor")
                                    .font(.body)
                                
                                if dashboardViewModel.heartRateMonitor.isConnected {
                                    Text("Connected • \(Int(dashboardViewModel.heartRateMonitor.heartRate)) BPM")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let lastDevice = dashboardViewModel.heartRateMonitor.lastConnectedDeviceName {
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
                        PowerMonitorView(powerMonitor: dashboardViewModel.powerMonitor)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundStyle(dashboardViewModel.powerMonitor.isConnected ? Color.green : Color("fairyRed"))
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Power Meter")
                                    .font(.body)
                                
                                if dashboardViewModel.powerMonitor.isConnected {
                                    Text("Connected • \(Int(dashboardViewModel.powerMonitor.threeSecondPower)) W")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let lastDevice = dashboardViewModel.powerMonitor.lastConnectedDeviceName {
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
    SettingsView(dashboardViewModel: Dashboard.ViewModel())
}

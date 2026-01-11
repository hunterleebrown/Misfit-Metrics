//
//  SettingsView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI
import PhotosUI
import Combine
import KeychainSwift

struct SettingsView: View {
    @Bindable var dashboardViewModel: Dashboard.ViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(StravaAuthenticationSession.self) private var stravaAuth
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var stravaAuthViewModel: StravaAuthorizationViewModel?
    
    var body: some View {
        NavigationStack {
            List {
                // Strava Section
                Section {
                    if stravaAuth.isAuthenticated {
                        // Authenticated State
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Connected to Strava")
                                    .font(.body)
                                
                                if let athlete = Settings.shared.getAuthResponse()?.athlete,
                                   let name = athlete.fullName {
                                    Text(name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Account active")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Button(role: .destructive) {
                            stravaAuth.logout()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Disconnect")
                            }
                        }
                        
                        // Debug link (remove in production)
                        NavigationLink("Debug Info") {
                            StravaDebugView()
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    } else {
                        // Not Authenticated State
                        Button {
                            stravaAuthViewModel?.authenticate()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "figure.outdoor.cycle")
                                    .foregroundStyle(Color("fairyRed"))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connect to Strava")
                                        .font(.body)
                                    
                                    Text("Upload activities and sync your rides")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Strava")
                } footer: {
                    if stravaAuth.isAuthenticated {
                        if let expiryDate = stravaAuth.expiryDate {
                            Text("Access expires: \(expiryDate.formatted(date: .abbreviated, time: .shortened))")
                        }
                    } else {
                        Text("Connect your Strava account to automatically upload your rides and access your activity history.")
                    }
                }
                
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
                        Text("Custom Photo").tag(Dashboard.BackgroundLook.userPhoto)
                    }
                    
                    PhotosPicker(
                        selection: $dashboardViewModel.photoPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundStyle(Color("fairyRed"))
                            Text("Choose Photo")
                            
                            Spacer()
                            
                            if let photo = dashboardViewModel.userBackgroundPhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                } header: {
                    Text("Dashboard Background")
                } footer: {
                    if dashboardViewModel.backgroundLook == .userPhoto && dashboardViewModel.userBackgroundPhoto != nil {
                        Text("Your custom photo is set as the background.")
                    } else if dashboardViewModel.backgroundLook == .userPhoto {
                        Text("Select a photo to use as your custom background.")
                    }
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
            .task {
                // Initialize the auth view model with the auth session from environment
                stravaAuthViewModel = StravaAuthorizationViewModel(authSession: stravaAuth)
            }
        }
    }
}

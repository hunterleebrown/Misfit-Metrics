//
//  StravaDebugView.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import SwiftUI
import KeychainSwift

/// A debugging view to help test and verify Strava authentication
struct StravaDebugView: View {
    @StateObject private var stravaAuth = StravaAuthenticationSession.shared
    @State private var authResponse: StravaAuthResponse?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Authentication Status") {
                    LabeledContent("Is Authenticated", value: stravaAuth.isAuthenticated ? "✅ Yes" : "❌ No")
                    LabeledContent("Is Expired", value: stravaAuth.expired ? "⚠️ Yes" : "✅ No")
                    
                    if let expiryDate = stravaAuth.expireyDate {
                        LabeledContent("Expires At", value: expiryDate.formatted())
                    }
                }
                
                if let response = authResponse {
                    Section("Token Info") {
                        if let tokenType = response.tokenType {
                            LabeledContent("Token Type", value: tokenType)
                        }
                        
                        if let expiresAt = response.expiresAt {
                            let date = Date(timeIntervalSince1970: Double(expiresAt))
                            LabeledContent("Expires At", value: date.formatted())
                        }
                        
                        if let expiresIn = response.expiresIn {
                            LabeledContent("Expires In", value: "\(expiresIn) seconds")
                        }
                        
                        if response.accessToken != nil {
                            LabeledContent("Access Token", value: "✅ Present (hidden)")
                        }
                        
                        if response.refreshToken != nil {
                            LabeledContent("Refresh Token", value: "✅ Present (hidden)")
                        }
                    }
                    
                    if let athlete = response.athlete {
                        Section("Athlete Info") {
                            if let name = athlete.fullName {
                                LabeledContent("Name", value: name)
                            }
                            
                            if let username = athlete.username {
                                LabeledContent("Username", value: username)
                            }
                            
                            if let city = athlete.city {
                                LabeledContent("City", value: city)
                            }
                            
                            if let state = athlete.state {
                                LabeledContent("State", value: state)
                            }
                            
                            LabeledContent("Strava ID", value: "\(athlete.stravaId)")
                        }
                    }
                }
                
                Section("Keychain") {
                    Button("Check Token in Keychain") {
                        if let token = Settings.shared.keychain.get("token") {
                            print("✅ Token found in keychain: \(token.prefix(10))...")
                        } else {
                            print("❌ No token found in keychain")
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Refresh Data") {
                        refreshData()
                    }
                    
                    Button("Check Expiration") {
                        stravaAuth.checkExpiration()
                    }
                }
            }
            .navigationTitle("Strava Debug")
            .onAppear {
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        authResponse = Settings.shared.getAuthResponse()
    }
}

#Preview {
    StravaDebugView()
}

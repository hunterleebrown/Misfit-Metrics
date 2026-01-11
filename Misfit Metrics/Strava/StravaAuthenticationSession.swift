//
//  StravaAuthenticationSession.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import SwiftUI
import Combine
import KeychainSwift

@Observable
final class StravaAuthenticationSession {
    var isAuthenticated: Bool = false
    var expiryDate: Date?
    
    /// Computed property to check if token is expired
    var isExpired: Bool {
        guard let expiryDate else { return true }
        return Date() >= expiryDate
    }
    
    // MARK: - Initialization
    
    init() {
        loadAuthenticationState()
    }
    
    /// Load authentication state from saved credentials
    func loadAuthenticationState() {
        guard let stravaResponse = Settings.shared.getAuthResponse(),
              stravaResponse.accessToken != nil,
              let expiresAt = stravaResponse.expiresAt else {
            isAuthenticated = false
            expiryDate = nil
            return
        }
        
        let expiry = Date(timeIntervalSince1970: Double(expiresAt))
        expiryDate = expiry
        
        // Only mark as authenticated if token hasn't expired
        isAuthenticated = Date() < expiry
    }
    
    // MARK: - Authentication Actions
    
    /// Update authentication state after login or logout
    func updateAuthentication(loggedIn: Bool) {
        if loggedIn {
            // Reload from saved credentials
            loadAuthenticationState()
        } else {
            // Clear state
            isAuthenticated = false
            expiryDate = nil
        }
    }
    
    /// Log out and clear credentials
    func logout() {
        Settings.shared.removeAuthResponse()
        Settings.shared.removeAccessToken()
        updateAuthentication(loggedIn: false)
    }
    
    // MARK: - Token Exchange
    
    func fetchStravaToken(stravaCode: String) async throws {
        let url = URL(string: "https://www.strava.com/api/v3/oauth/token")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&client_secret=\(StravaConfig.shared.stravaValue(.client_secret)!)&code=\(stravaCode)&grant_type=authorization_code"
        
        request.httpBody = postString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode)"])
        }
        
        let stravaResponse = try JSONDecoder().decode(StravaAuthResponse.self, from: data)
        Settings.shared.setAuthResponse(stravaResponse)
        
        // Update authentication state
        updateAuthentication(loggedIn: true)
    }
    
    // MARK: - URL Parsing
    
    func getStravaCode(url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }
}


//
//  StravaAuthorizationViewModel.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import Foundation
import AuthenticationServices
import Combine

@Observable
final class StravaAuthorizationViewModel: NSObject {
    private var asWebAuthSession: ASWebAuthenticationSession?
    private let authSession: StravaAuthenticationSession
    
    var isAuthenticating: Bool = false
    
    static let scope = "read%2Cread_all%2Cprofile%3Aread_all%2Cactivity%3Aread_all"
    
    init(authSession: StravaAuthenticationSession) {
        self.authSession = authSession
        super.init()
    }
    
    private var appOAuthUrlStravaScheme: URL {
        URL(string: "strava://oauth/mobile/authorize?client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&redirect_uri=\(StravaConfig.shared.stravaValue(.appname)!)%3A%2F%2F\(StravaConfig.shared.stravaValue(.website)!)&response_type=code&approval_prompt=auto&scope=\(Self.scope)&state=test")!
    }
    
    private var webOAuthUrl: URL {
        URL(string: "https://www.strava.com/oauth/mobile/authorize?client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&redirect_uri=\(StravaConfig.shared.stravaValue(.appname)!)%3A%2F%2F\(StravaConfig.shared.stravaValue(.website)!)&response_type=code&approval_prompt=auto&scope=\(Self.scope)&state=test")!
    }
    
    func authenticate() {
        isAuthenticating = true
        
        // Check if Strava app is installed and can handle the auth
        if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
            // Open Strava app directly - the callback will be handled by .onOpenURL in the main app
            UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
        } else {
            // Use ASWebAuthenticationSession for web-based auth
            asWebAuthSession = ASWebAuthenticationSession(
                url: webOAuthUrl,
                callbackURLScheme: "misfit-metrics") { [weak self] url, error in
                    guard let self else { return }
                    
                    defer { self.isAuthenticating = false }
                    
                    if let error {
                        print("Authentication error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let url,
                          let code = self.authSession.getStravaCode(url: url) else {
                        print("Failed to extract code from callback URL")
                        return
                    }
                    
                    Task { @MainActor in
                        do {
                            try await self.authSession.fetchStravaToken(stravaCode: code)
                        } catch {
                            print("Failed to fetch token: \(error)")
                        }
                    }
            }
            asWebAuthSession?.presentationContextProvider = self
            asWebAuthSession?.prefersEphemeralWebBrowserSession = false
            asWebAuthSession?.start()
        }
    }
    
    /// Handle deep link callback from Strava app
    func handleCallback(url: URL) async {
        defer { isAuthenticating = false }
        
        guard let code = authSession.getStravaCode(url: url) else {
            print("Failed to extract code from callback URL")
            return
        }
        
        do {
            try await authSession.fetchStravaToken(stravaCode: code)
        } catch {
            print("Failed to fetch token: \(error)")
        }
    }
}

extension StravaAuthorizationViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the first connected scene that is a UIWindowScene
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            // Fallback to any UIWindowScene if no active one is found
            guard let windowScene = UIApplication.shared.connectedScenes
                .first as? UIWindowScene else {
                fatalError("No window scene available")
            }
            return ASPresentationAnchor(windowScene: windowScene)
        }
        return ASPresentationAnchor(windowScene: windowScene)
    }
}

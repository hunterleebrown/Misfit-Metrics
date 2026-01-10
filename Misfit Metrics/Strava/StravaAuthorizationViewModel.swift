//
//  StravaAuthorizationViewModel.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import Foundation
import AuthenticationServices
import Combine

class StravaAuthorizationViewModel: NSObject, ObservableObject {
    private var asWebAuthSession: ASWebAuthenticationSession?

    static var loginEvent = PassthroughSubject<Bool, Never>()

    static let scope = "read%2Cread_all%2Cprofile%3Aread_all%2Cactivity%3Aread_all"

    let appOAuthUrlStravaScheme = URL(string: "strava://oauth/mobile/authorize?client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&redirect_uri=\(StravaConfig.shared.stravaValue(.appname)!)%3A%2F%2F\(StravaConfig.shared.stravaValue(.website)!)&response_type=code&approval_prompt=auto&scope=\(scope)&state=test")!

    let webOAuthUrl = URL(string: "https://www.strava.com/oauth/mobile/authorize?client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&redirect_uri=\(StravaConfig.shared.stravaValue(.appname)!)%3A%2F%2F\(StravaConfig.shared.stravaValue(.website)!)&response_type=code&approval_prompt=auto&scope=\(scope)&state=test")!

    func authenticate() {
        // Check if Strava app is installed and can handle the auth
        if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
            // Open Strava app directly - the callback will be handled by .onOpenURL in the main app
            UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
        } else {
            // Use ASWebAuthenticationSession for web-based auth
            // Note: ASWebAuthenticationSession only supports HTTP/HTTPS URLs
            asWebAuthSession = ASWebAuthenticationSession(
                url: webOAuthUrl,
                callbackURLScheme: "misfit-metrics") { url, error in
                    guard let url = url, let code = StravaAuthenticationSession.shared.getStravaCode(url: url) else { 
                        return 
                    }
                    StravaAuthenticationSession.shared.fetchStravaToken(stravCode: code)
            }
            asWebAuthSession?.presentationContextProvider = self
            asWebAuthSession?.prefersEphemeralWebBrowserSession = false  // Allow cookie sharing for better UX
            asWebAuthSession?.start()
        }
    }
}

extension StravaAuthorizationViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession)
     -> ASPresentationAnchor {
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

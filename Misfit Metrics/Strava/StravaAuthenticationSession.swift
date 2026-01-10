//
//  StravaAuthenticationSession.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import SwiftUI
import Combine

class StravaAuthenticationSession: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var expired: Bool = true

    func updateAuthentication(loggedIn: Bool) {
        isAuthenticated = loggedIn
    }

    static let shared = StravaAuthenticationSession()

    var expireyDate: Date?

    init() {

        guard let stravaResponse = Settings.shared.getAuthResponse(),
              let _ = stravaResponse.accessToken,
              let expiresDate = stravaResponse.expiresAt else { return }

        let now = Date()
        expireyDate = Date(timeIntervalSince1970: Double(expiresDate))
        if let exd = expireyDate {
            if (now < exd) {
                isAuthenticated = true
            }
        }
    }

    func checkExpiration() {
        print("Exp")
        dump(expireyDate)
        print("Now")
        dump(Date())
        let now = Date()
        if let exd = expireyDate {
            if (now < exd) {
                expired = false
                print("-----> I think it's not expired.")
                return
            }
        }
        expired = true
        print("-----> I think it is expired.")

    }

    func fetchStravaToken(stravCode: String) {

        Task {
            let url = URL(string: "https://www.strava.com/api/v3/oauth/token")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let postString = "client_id=\(StravaConfig.shared.stravaValue(.client_id)!)&client_secret=\(StravaConfig.shared.stravaValue(.client_secret)!)&code=\(stravCode)&grant_type=authorization_code"

            request.httpBody = postString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    let error = NSError(domain: "HTTP Error", code: httpStatus.statusCode, userInfo: nil)
                    print("\(error)")
                }
                let stravaResponse = try JSONDecoder().decode(StravaAuthResponse.self, from: data)
                Settings.shared.setAuthResponse(stravaResponse)
                DispatchQueue.main.async {
                    StravaAuthorizationViewModel.loginEvent.send(true)
                }
            } catch (let error) {
                print("\(error)")
            }
        }
    }



    func getStravaCode(url: URL) -> String? {
        // longestrides://www.hunterleebrown.com?state=test&code=1338d2dab9f0de09fd5e69063abb98e4bbd29fc7&scope=read,activity:write
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
            return code
        }

        return nil
    }

}


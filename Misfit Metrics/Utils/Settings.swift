//
//  Settings.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import Foundation
import KeychainSwift
import SwiftUI

class Settings {

    static let shared = Settings()

    public var keychain: KeychainSwift

    static var foregroundColor: Color = Color("Foreground")
    static var backgroundColor: Color = Color("Background")
    static var fillColor: Color = Color("FillColor")

    private static let keyChainPrefix =  "longestRides"

    init() {
        keychain = KeychainSwift(keyPrefix: Settings.keyChainPrefix)
    }

    enum Key: String {
        case authResponse
        case activities
        case segments
        case segmentefforts
    }

    private lazy var jsonEncoder: JSONEncoder = {
        JSONEncoder()
    }()

    private lazy var jsonDecoder: JSONDecoder = {
        JSONDecoder()
    }()

    func setAuthResponse(_ stravaResponse: StravaAuthResponse) {
        if let token = stravaResponse.accessToken {
            self.keychain.set(token, forKey: "token")
            stravaResponse.accessToken = nil
        }
        if let encoded = try? jsonEncoder.encode(stravaResponse) {
            UserDefaults.standard.set(encoded, forKey: Key.authResponse.rawValue)
            UserDefaults.standard.synchronize()
        }
    }

    func getAuthResponse() -> StravaAuthResponse? {
        if let stravaResponse = UserDefaults.standard.object(forKey: Key.authResponse.rawValue) as? Data {
            if let savedStravaResponse = try? jsonDecoder.decode(StravaAuthResponse.self, from: stravaResponse) {
                if let token = keychain.get("token") {
                    savedStravaResponse.accessToken = token
                }
                return savedStravaResponse
            }
        }
        return nil
    }

    public func removeAuthResponse() {
        UserDefaults.standard.removeObject(forKey: Key.authResponse.rawValue)
    }
}

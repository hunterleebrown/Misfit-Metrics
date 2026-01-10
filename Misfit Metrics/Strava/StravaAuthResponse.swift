//
//  StravaAuthResponse.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import Foundation

public class StravaAuthResponse: Codable {
    public var tokenType: String?
    public var expiresAt: Int?
    public var expiresIn: Int?
    public var refreshToken: String?
    public var accessToken: String?
    public var athlete: StravaAthlete?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case athlete
    }

    private lazy var dateFormatter: DateFormatter = {
        return DateFormatter()
    }()

    var expireDate: String? {
        get {
            if let expires = expiresAt {
                let date = Date(timeIntervalSince1970: Double(expires))
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd, YYYY HH:mm:ss")
                return dateFormatter.string(from: date)
            }

            return nil
        }
    }
}

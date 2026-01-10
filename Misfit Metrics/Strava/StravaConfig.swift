//
//  StravaConfig.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

struct StravaConfig {

    static let shared = StravaConfig()

    static let clientId = "80133"
    static let clientSecret = "d7f8d0907c996a4188f4cf02fe025b03094147f9"
    static let appname = "misfit-metrics"
    static let website = "www.hunterleebrown.com"

    public enum StravaConfigKey: String {
        case client_id
        case client_secret
        case appname
        case website
    }

    public func stravaValue(_ key: StravaConfigKey) -> String? {
        return stravaValues[key.rawValue] ?? nil
    }

    private var stravaValues: [String: String] = {
        return [
            StravaConfig.StravaConfigKey.client_id.rawValue : StravaConfig.clientId,
            StravaConfig.StravaConfigKey.client_secret.rawValue : StravaConfig.clientSecret,
            StravaConfig.StravaConfigKey.appname.rawValue : StravaConfig.appname,
            StravaConfig.StravaConfigKey.website.rawValue : StravaConfig.website
        ]
    }()
}

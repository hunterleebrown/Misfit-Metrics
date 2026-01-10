//
//  StravaAthlete.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import SwiftUI
import SwiftData

@Model
public class StravaAthlete: Codable {

    public var stravaId: Int64
    public var username: String?
    public var firstname: String?
    public var lastname: String?
    public var city: String?
    public var state: String?
    public var sex: String?
    public var profile: String?

    enum CodingKeys: String, CodingKey {
        case stravaId = "id"
        case username
        case firstname
        case lastname
        case city
        case state
        case sex
        case profile
    }

    init(stravaId: Int64, username: String? = nil, firstname: String? = nil, lastname: String? = nil, city: String? = nil, state: String? = nil, sex: String? = nil, profile: String? = nil) {
        self.stravaId = stravaId
        self.username = username
        self.firstname = firstname
        self.lastname = lastname
        self.city = city
        self.state = state
        self.sex = sex
        self.profile = profile
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        stravaId = try container.decode(Int64.self, forKey: .stravaId)
        username = try? container.decodeIfPresent(String.self, forKey: .username)
        firstname = try? container.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try? container.decodeIfPresent(String.self, forKey: .lastname)
        city = try? container.decodeIfPresent(String.self, forKey: .city)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
        sex = try? container.decodeIfPresent(String.self, forKey: .sex)
        profile = try? container.decodeIfPresent(String.self, forKey: .profile)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encodeIfPresent(stravaId, forKey: .stravaId)
        try? container.encodeIfPresent(username, forKey: .username)
        try? container.encodeIfPresent(firstname, forKey: .firstname)
        try? container.encodeIfPresent(lastname, forKey: .lastname)
        try? container.encodeIfPresent(city, forKey: .city)
        try? container.encodeIfPresent(state, forKey: .state)
        try? container.encodeIfPresent(sex, forKey: .sex)
        try? container.encodeIfPresent(profile, forKey: .profile)
    }

    var profileUrl: URL? {
        get {
            if let profileImagePath = self.profile {
                return URL(string: profileImagePath)
            }

            return nil
        }
    }

    var fullName: String? {
        guard let firstname = firstname else { return nil }

        if let lastname = lastname {
            return "\(firstname) \(lastname)"
        } else {
            return firstname
        }
    }
}

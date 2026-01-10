//
//  DataModels.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import Foundation
import SwiftData

@Model
final class MisfitAdventure {
    var startTime: Date
    var endTime: Date?
    
    @Relationship(deleteRule: .cascade)
    var records: [MisfitRecord] = []

    // Summary data (calculated when stopped)
    var totalDistance: Double?
    var averageHeartRate: Int?
    var averagePower: Double?

    init(startTime: Date, endTime: Date? = nil, records: [MisfitRecord] = [], totalDistance: Double? = nil, averageHeartRate: Int? = nil, averagePower: Double? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.records = records
        self.totalDistance = totalDistance
        self.averageHeartRate = averageHeartRate
        self.averagePower = averagePower
    }
}

@Model
final class MisfitRecord {
    var id: UUID
    var timestamp: Date
    
    // Location data
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?  // in meters
    
    // Performance metrics
    var heartRate: Int?
    var power: Double?
    var speed: Double?  // in mph
    var cadence: Int?  // RPM
    
    // Cumulative distance in miles
    var distance: Double
    
    init(
        id: UUID = UUID(),
        timestamp: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        heartRate: Int? = nil,
        power: Double? = nil,
        speed: Double? = nil,
        cadence: Int? = nil,
        distance: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.heartRate = heartRate
        self.power = power
        self.speed = speed
        self.cadence = cadence
        self.distance = distance
    }
}

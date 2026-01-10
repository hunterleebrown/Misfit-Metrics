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
    var speed: Double?
    
    init(id: UUID = UUID(), timestamp: Date, speed: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.speed = speed
    }
}

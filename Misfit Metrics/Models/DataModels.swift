//
//  DataModels.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class MisfitAdventure {
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
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

struct MisfitRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var speed: Double?
}

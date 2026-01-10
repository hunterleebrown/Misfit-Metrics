//
//  MisfitFITEncoder.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import Foundation
import FITSwiftSDK

/// Encodes MisfitAdventure objects into FIT files using the FITSwiftSDK
@available(*, unavailable)
extension MisfitFITEncoder: Sendable {}

final class MisfitFITEncoder: @unchecked Sendable {
    
    enum EncoderError: Error {
        case noEndTime
        case noRecords
        case invalidData
    }
    
    /// Converts a MisfitAdventure to a FIT file and returns the encoded data
    /// - Parameter adventure: The MisfitAdventure to encode
    /// - Returns: Data representing the FIT file
    /// - Throws: EncoderError if the adventure is invalid or encoding fails
    func encode(adventure: MisfitAdventure) throws -> Data {
        guard let endTime = adventure.endTime else {
            throw EncoderError.noEndTime
        }
        
        guard !adventure.records.isEmpty else {
            throw EncoderError.noRecords
        }
        
        var messages: [Mesg] = []
        
        // Convert dates to FIT DateTime
        let startTime = DateTime(adventure.startTime)
        let timestamp = DateTime(endTime)
        
        // Timer Events are a BEST PRACTICE for FIT ACTIVITY files
        let eventMesgStart = EventMesg()
        try eventMesgStart.setTimestamp(startTime)
        try eventMesgStart.setEvent(.timer)
        try eventMesgStart.setEventType(.start)
        messages.append(eventMesgStart)
        
        // Create Record messages for each data point
        for record in adventure.records {
            let recordMesg = RecordMesg()
            let recordTimestamp = DateTime(record.timestamp)
            try recordMesg.setTimestamp(recordTimestamp)
            
            // Distance (convert miles to meters: 1 mile = 1609.34 meters)
            let distanceMeters = record.distance * 1609.34
            try recordMesg.setDistance(distanceMeters)
            
            // Speed (convert mph to m/s: 1 mph = 0.44704 m/s)
            if let speed = record.speed {
                let speedMetersPerSecond = speed * 0.44704
                try recordMesg.setSpeed(speedMetersPerSecond)
            }
            
            // Heart Rate
            if let heartRate = record.heartRate {
                try recordMesg.setHeartRate(UInt8(heartRate))
            }
            
            // Power
            if let power = record.power {
                try recordMesg.setPower(UInt16(power))
            }
            
            // Cadence
            if let cadence = record.cadence {
                try recordMesg.setCadence(UInt8(cadence))
            }
            
            // Altitude
            if let altitude = record.altitude {
                try recordMesg.setAltitude(altitude)
            }
            
            // Position (convert to semicircles: degrees * (2^31 / 180))
            if let latitude = record.latitude, let longitude = record.longitude {
                let latSemicircles = Int32(latitude * 2147483648.0 / 180.0)
                let lonSemicircles = Int32(longitude * 2147483648.0 / 180.0)
                try recordMesg.setPositionLat(latSemicircles)
                try recordMesg.setPositionLong(lonSemicircles)
            }
            
            messages.append(recordMesg)
        }
        
        // Timer Events are a BEST PRACTICE for FIT ACTIVITY files
        let eventMesgStop = EventMesg()
        try eventMesgStop.setTimestamp(timestamp)
        try eventMesgStop.setEvent(.timer)
        try eventMesgStop.setEventType(.stopAll)
        messages.append(eventMesgStop)
        
        // Calculate total elapsed time
        let totalElapsedTime = endTime.timeIntervalSince(adventure.startTime)
        
        // Every FIT ACTIVITY file MUST contain at least one Lap message
        let lapMesg = LapMesg()
        try lapMesg.setMessageIndex(0)
        try lapMesg.setTimestamp(timestamp)
        try lapMesg.setStartTime(startTime)
        try lapMesg.setTotalElapsedTime(totalElapsedTime)
        try lapMesg.setTotalTimerTime(totalElapsedTime)
        
        // Add lap distance if available (convert miles to meters)
        if let distance = adventure.totalDistance {
            try lapMesg.setTotalDistance(distance * 1609.34)
        }
        
        // Add average heart rate if available
        if let avgHR = adventure.averageHeartRate {
            try lapMesg.setAvgHeartRate(UInt8(avgHR))
        }
        
        // Add average power if available
        if let avgPower = adventure.averagePower {
            try lapMesg.setAvgPower(UInt16(avgPower))
        }
        
        messages.append(lapMesg)
        
        // Every FIT ACTIVITY file MUST contain at least one Session message
        let sessionMesg = SessionMesg()
        try sessionMesg.setMessageIndex(0)
        try sessionMesg.setTimestamp(timestamp)
        try sessionMesg.setStartTime(startTime)
        try sessionMesg.setTotalElapsedTime(totalElapsedTime)
        try sessionMesg.setTotalTimerTime(totalElapsedTime)
        try sessionMesg.setSport(.cycling)  // Assuming cycling based on "bicycle" icon
        try sessionMesg.setSubSport(.generic)
        try sessionMesg.setFirstLapIndex(0)
        try sessionMesg.setNumLaps(1)
        
        // Add session distance if available (convert miles to meters)
        if let distance = adventure.totalDistance {
            try sessionMesg.setTotalDistance(distance * 1609.34)
        }
        
        // Add average heart rate if available
        if let avgHR = adventure.averageHeartRate {
            try sessionMesg.setAvgHeartRate(UInt8(avgHR))
        }
        
        // Add average power if available
        if let avgPower = adventure.averagePower {
            try sessionMesg.setAvgPower(UInt16(avgPower))
        }
        
        messages.append(sessionMesg)
        
        // Every FIT ACTIVITY file MUST contain EXACTLY one Activity message
        let activityMesg = ActivityMesg()
        try activityMesg.setTimestamp(timestamp)
        try activityMesg.setTotalTimerTime(totalElapsedTime)
        try activityMesg.setNumSessions(1)
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        try activityMesg.setLocalTimestamp(LocalDateTime(Int(timestamp.timestamp) + timezoneOffset))
        messages.append(activityMesg)
        
        // Create the complete FIT file with all required messages
        return try createFITFile(messages: messages, startTime: startTime)
    }
    
    /// Creates a FIT file with the provided messages
    private func createFITFile(messages: [Mesg], startTime: DateTime) throws -> Data {
        // The combination of file type, manufacturer id, product id, and serial number should be unique.
        let fileType = File.activity
        let manufacturerId = Manufacturer.development
        let productId: UInt16 = 0
        let softwareVersion: Float32 = 1.0
        let serialNumber = UInt32.random(in: 1..<UInt32.max)
        
        // Every FIT file MUST contain a File ID message
        let fileIdMesg = FileIdMesg()
        try fileIdMesg.setType(fileType)
        try fileIdMesg.setManufacturer(manufacturerId)
        try fileIdMesg.setProduct(productId)
        try fileIdMesg.setTimeCreated(startTime)
        try fileIdMesg.setSerialNumber(serialNumber)
        
        // A Device Info message is a BEST PRACTICE for FIT ACTIVITY files
        let deviceInfoMesg = DeviceInfoMesg()
        try deviceInfoMesg.setDeviceIndex(DeviceIndexValues.creator)
        try deviceInfoMesg.setManufacturer(manufacturerId)
        try deviceInfoMesg.setProduct(productId)
        try deviceInfoMesg.setProductName("Misfit Metrics") // Max 20 Chars
        try deviceInfoMesg.setSerialNumber(serialNumber)
        try deviceInfoMesg.setSoftwareVersion(Float64(softwareVersion))
        try deviceInfoMesg.setTimestamp(startTime)
        
        // Create a FIT Encode object
        let encoder = Encoder()
        
        // Write the messages to the file, in the proper sequence
        encoder.write(mesg: fileIdMesg)
        encoder.write(mesg: deviceInfoMesg)
        encoder.write(mesgs: messages)
        
        // Update the data size in the header and calculate the CRC
        let encodedData = encoder.close()
        
        return encodedData
    }
    
    /// Saves a MisfitAdventure as a FIT file to the specified URL
    /// - Parameters:
    ///   - adventure: The adventure to save
    ///   - url: The destination URL for the FIT file
    /// - Throws: EncoderError or file system errors
    func saveFITFile(adventure: MisfitAdventure, to url: URL) throws {
        let data = try encode(adventure: adventure)
        try data.write(to: url)
    }
    
    /// Creates a suggested filename for a MisfitAdventure FIT file
    /// - Parameter adventure: The adventure to create a filename for
    /// - Returns: A filename in the format "MisfitMetrics_YYYY-MM-DD_HHMM.fit"
    func suggestedFilename(for adventure: MisfitAdventure) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = formatter.string(from: adventure.startTime)
        return "MisfitMetrics_\(dateString).fit"
    }
}

// Extension to create DateTime from Swift Date
extension DateTime {
    init(_ date: Date) {
        let timestamp = UInt32(date.timeIntervalSince1970 - 631065600) // FIT epoch offset
        self.init(timestamp: timestamp)
    }
}

//
//  StravaUploadService.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/10/26.
//

import Foundation

/// Service for uploading activities to Strava
final class StravaUploadService {
    
    // MARK: - Upload Response
    
    struct UploadResponse: Codable {
        let id: Int
        let externalId: String?
        let error: String?
        let status: String
        let activityId: Int?
        
        enum CodingKeys: String, CodingKey {
            case id
            case externalId = "external_id"
            case error
            case status
            case activityId = "activity_id"
        }
    }
    
    // MARK: - Upload Parameters
    
    struct UploadParameters {
        let fileURL: URL
        let dataType: DataType
        let name: String?
        let description: String?
        let activityType: ActivityType?
        let externalId: String?
        
        /// Convenience initializer for FIT file items
        init(fitFileItem: FITFileItem, name: String? = nil, description: String? = nil, activityType: ActivityType? = nil) {
            self.fileURL = fitFileItem.url
            self.dataType = .fit
            self.name = name
            self.description = description
            self.activityType = activityType
            // Use filename as external ID to prevent duplicate uploads
            self.externalId = fitFileItem.filename
        }
        
        init(fileURL: URL, dataType: DataType, name: String? = nil, description: String? = nil, activityType: ActivityType? = nil, externalId: String? = nil) {
            self.fileURL = fileURL
            self.dataType = dataType
            self.name = name
            self.description = description
            self.activityType = activityType
            self.externalId = externalId
        }
        
        enum DataType: String {
            case fit
            case gpx
            case tcx
        }
        
        enum ActivityType: String {
            case ride
            case run
            case swim
            case walk
            case hike
            case alpineSki = "alpineski"
            case backcountrySki = "backcountryski"
            case canoeing
            case crossfit
            case ebikeRide = "ebikeride"
            case elliptical
            case golf
            case handcycle
            case iceSkate = "iceskate"
            case inlineSkate = "inlineskate"
            case kayaking
            case kitesurf
            case nordicSki = "nordicski"
            case rockClimbing = "rockclimbing"
            case rollerSki = "rollerski"
            case rowing
            case snowboard
            case snowshoe
            case soccer
            case stairStepper = "stairstepper"
            case standUpPaddling = "standuppaddling"
            case surfing
            case velomobile
            case virtualRide = "virtualride"
            case virtualRun = "virtualrun"
            case weightTraining = "weighttraining"
            case wheelchair
            case windsurf
            case workout
            case yoga
        }
    }
    
    // MARK: - Errors
    
    enum UploadError: LocalizedError {
        case noAccessToken
        case invalidFileURL
        case uploadFailed(String)
        case rateLimitExceeded
        
        var errorDescription: String? {
            switch self {
            case .noAccessToken:
                return "No access token available. Please authenticate with Strava."
            case .invalidFileURL:
                return "The file URL is invalid or the file cannot be read."
            case .uploadFailed(let message):
                return "Upload failed: \(message)"
            case .rateLimitExceeded:
                return "Strava rate limit exceeded. Please try again later."
            }
        }
    }
    
    // MARK: - Upload Method
    
    /// Upload a FIT file to Strava
    /// - Parameter parameters: Upload parameters including file URL and metadata
    /// - Returns: Upload response containing upload ID and status
    func upload(parameters: UploadParameters) async throws -> UploadResponse {
        // Get access token
        guard let authResponse = Settings.shared.getAuthResponse(),
              let accessToken = authResponse.accessToken else {
            throw UploadError.noAccessToken
        }
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: parameters.fileURL.path) else {
            throw UploadError.invalidFileURL
        }
        
        // Read file data
        let fileData = try Data(contentsOf: parameters.fileURL)
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        let httpBody = createMultipartBody(
            fileData: fileData,
            fileName: parameters.fileURL.lastPathComponent,
            parameters: parameters,
            boundary: boundary
        )
        
        // Create request
        let url = URL(string: "https://www.strava.com/api/v3/uploads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        // Perform upload
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.uploadFailed("Invalid response")
        }
        
        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw UploadError.rateLimitExceeded
        }
        
        // Check for success
        guard httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw UploadError.uploadFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
        
        // Decode response
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        // Check for errors in response
        if let error = uploadResponse.error {
            throw UploadError.uploadFailed(error)
        }
        
        return uploadResponse
    }
    
    // MARK: - Check Upload Status
    
    /// Check the status of an upload
    /// - Parameter uploadId: The upload ID returned from the upload request
    /// - Returns: Updated upload response with current status
    func checkUploadStatus(uploadId: Int) async throws -> UploadResponse {
        guard let authResponse = Settings.shared.getAuthResponse(),
              let accessToken = authResponse.accessToken else {
            throw UploadError.noAccessToken
        }
        
        let url = URL(string: "https://www.strava.com/api/v3/uploads/\(uploadId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UploadError.uploadFailed("Failed to check upload status")
        }
        
        return try JSONDecoder().decode(UploadResponse.self, from: data)
    }
    
    // MARK: - Multipart Form Data Creation
    
    private func createMultipartBody(
        fileData: Data,
        fileName: String,
        parameters: UploadParameters,
        boundary: String
    ) -> Data {
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        
        // Add data_type
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"data_type\"\r\n\r\n")
        body.append(parameters.dataType.rawValue)
        body.append("\r\n")
        
        // Add optional parameters
        if let name = parameters.name {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n")
            body.append(name)
            body.append("\r\n")
        }
        
        if let description = parameters.description {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"description\"\r\n\r\n")
            body.append(description)
            body.append("\r\n")
        }
        
        if let activityType = parameters.activityType {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"activity_type\"\r\n\r\n")
            body.append(activityType.rawValue)
            body.append("\r\n")
        }
        
        if let externalId = parameters.externalId {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"external_id\"\r\n\r\n")
            body.append(externalId)
            body.append("\r\n")
        }
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n")
        
        return body
    }
}

// MARK: - Data Extension

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

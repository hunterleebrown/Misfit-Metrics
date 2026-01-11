//
//  MisfitAdventures.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MisfitAdventures: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MisfitAdventure.startTime, order: .reverse) private var adventures: [MisfitAdventure]
    
    @State private var adventureToDelete: MisfitAdventure?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            ForEach(adventures) { adventure in
                AdventureRow(adventure: adventure)
                    .listRowSeparator(.hidden)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .padding(.vertical, 4)
                    )
            }
            .onDelete(perform: handleDelete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Adventures")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            EditButton()
        }
        .alert("Delete Adventure?", isPresented: $showingDeleteConfirmation, presenting: adventureToDelete) { adventure in
            Button("Cancel", role: .cancel) {
                adventureToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteAdventure(adventure)
            }
        } message: { adventure in
            Text("Are you sure you want to delete this adventure from \(adventure.startTime.formatted(date: .abbreviated, time: .shortened))?")
        }
        .overlay {
            if adventures.isEmpty {
                ContentUnavailableView(
                    "No Adventures Yet",
                    systemImage: "bicycle",
                    description: Text("Your adventures will appear here after you complete a ride")
                )
            }
        }
    }
    
    private func handleDelete(at offsets: IndexSet) {
        // Show confirmation for the first item in the set
        if let index = offsets.first {
            adventureToDelete = adventures[index]
            showingDeleteConfirmation = true
        }
    }
    
    private func deleteAdventure(_ adventure: MisfitAdventure) {
        withAnimation {
            modelContext.delete(adventure)
            adventureToDelete = nil
        }
    }
}
struct AdventureRow: View {
    let adventure: MisfitAdventure
    
    @State private var showingExportSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date and time
            Text(adventure.startTime.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            
            // Stats row
            HStack(spacing: 16) {
                if let distance = adventure.totalDistance {
                    Label(formatDistance(distance), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                        .font(.subheadline)
                }
                
                if let duration = adventure.endTime?.timeIntervalSince(adventure.startTime) {
                    Label(formatDuration(duration), systemImage: "clock")
                        .font(.subheadline)
                }
                
                if let avgHR = adventure.averageHeartRate {
                    Label("\(avgHR) bpm", systemImage: "heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                
                if let avgPower = adventure.averagePower {
                    Label(String(format: "%.0f W", avgPower), systemImage: "bolt.fill")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                }
            }
            .foregroundStyle(.secondary)
            
            // Record count
            Text("\(adventure.records.count) data points")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showingExportSheet = true
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(adventure: adventure)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func formatDistance(_ miles: Double) -> String {
        if miles < 0.25 {
            let feet = miles * 5280
            return String(format: "%.0f ft", feet)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// Transferable wrapper for FIT files to work with ShareLink
struct FITFileItem: Transferable {
    let url: URL
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .data) { item in
            SentTransferredFile(item.url)
        }
    }
}

// MARK: - Strava Upload Sheet

struct StravaUploadSheet: View {
    let fitFileItem: FITFileItem
    let adventure: MisfitAdventure
    
    @Environment(\.dismiss) private var dismiss
    @State private var uploadService = StravaUploadService()
    
    @State private var activityName: String = ""
    @State private var activityDescription: String = ""
    @State private var activityType: StravaUploadService.UploadParameters.ActivityType = .ride
    
    @State private var isUploading = false
    @State private var uploadStatus: UploadStatus = .notStarted
    @State private var uploadResponse: StravaUploadService.UploadResponse?
    @State private var errorMessage: String?
    
    enum UploadStatus {
        case notStarted
        case uploading
        case processing
        case success
        case failed
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Activity Name", text: $activityName)
                    TextField("Description (optional)", text: $activityDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Activity Type", selection: $activityType) {
                        Text("Ride").tag(StravaUploadService.UploadParameters.ActivityType.ride)
                        Text("Run").tag(StravaUploadService.UploadParameters.ActivityType.run)
                        Text("Walk").tag(StravaUploadService.UploadParameters.ActivityType.walk)
                        Text("Hike").tag(StravaUploadService.UploadParameters.ActivityType.hike)
                        Text("E-Bike Ride").tag(StravaUploadService.UploadParameters.ActivityType.ebikeRide)
                        Text("Virtual Ride").tag(StravaUploadService.UploadParameters.ActivityType.virtualRide)
                    }
                }
                
                Section("Upload Status") {
                    switch uploadStatus {
                    case .notStarted:
                        Label("Ready to upload", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                        
                    case .uploading:
                        HStack {
                            ProgressView()
                            Text("Uploading to Strava...")
                        }
                        
                    case .processing:
                        HStack {
                            ProgressView()
                            Text("Processing activity...")
                        }
                        
                    case .success:
                        Label("Upload successful!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        if let response = uploadResponse, let activityId = response.activityId {
                            Link("View on Strava", destination: URL(string: "https://www.strava.com/activities/\(activityId)")!)
                        }
                        
                    case .failed:
                        Label("Upload failed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack(spacing: 12) {
                        Text(fitFileItem.filename)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if let distance = adventure.totalDistance {
                            Label(formatDistance(distance), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Upload to Strava")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(uploadStatus == .success ? "Done" : "Upload") {
                        if uploadStatus == .success {
                            dismiss()
                        } else {
                            Task {
                                await performUpload()
                            }
                        }
                    }
                    .disabled(isUploading || activityName.isEmpty)
                }
            }
            .onAppear {
                // Pre-fill with adventure date
                if activityName.isEmpty {
                    activityName = adventure.startTime.formatted(date: .abbreviated, time: .shortened)
                }
            }
        }
    }
    
    private func performUpload() async {
        isUploading = true
        uploadStatus = .uploading
        errorMessage = nil
        
        do {
            let parameters = StravaUploadService.UploadParameters(
                fitFileItem: fitFileItem,
                name: activityName,
                description: activityDescription.isEmpty ? nil : activityDescription,
                activityType: activityType
            )
            
            let response = try await uploadService.upload(parameters: parameters)
            uploadResponse = response
            
            // If activity ID is not immediately available, poll for status
            if response.activityId == nil && response.status != "error" {
                uploadStatus = .processing
                try await checkUploadStatus(uploadId: response.id)
            } else if response.activityId != nil {
                uploadStatus = .success
            } else {
                uploadStatus = .failed
                errorMessage = response.error ?? "Unknown error"
            }
            
        } catch let error as StravaUploadService.UploadError {
            uploadStatus = .failed
            errorMessage = error.localizedDescription
        } catch {
            uploadStatus = .failed
            errorMessage = error.localizedDescription
        }
        
        isUploading = false
    }
    
    private func checkUploadStatus(uploadId: Int) async throws {
        // Poll up to 10 times with 2-second delays
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let status = try await uploadService.checkUploadStatus(uploadId: uploadId)
            uploadResponse = status
            
            if let activityId = status.activityId {
                uploadStatus = .success
                return
            } else if status.status == "error" {
                uploadStatus = .failed
                errorMessage = status.error ?? "Processing failed"
                return
            }
        }
        
        // If we get here, still processing but we'll stop polling
        uploadStatus = .success
        errorMessage = "Upload is processing. Check Strava in a few moments."
    }
    
    private func formatDistance(_ miles: Double) -> String {
        if miles < 0.25 {
            let feet = miles * 5280
            return String(format: "%.0f ft", feet)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
}

// MARK: - Export View Model

@MainActor
@Observable
final class ExportViewModel {
    let adventure: MisfitAdventure
    
    var shareItem: FITFileItem?
    var isGenerating = false
    var showingStravaUpload = false
    var errorMessage: String?
    
    init(adventure: MisfitAdventure) {
        self.adventure = adventure
    }
    
    func generateFITFile() async {
        // Prevent multiple simultaneous generations
        guard !isGenerating, shareItem == nil else { return }
        
        isGenerating = true
        errorMessage = nil
        
        // Show estimated time for large datasets
        if adventure.records.count > 5000 {
            print("⏱️ Large dataset detected (\(adventure.records.count) records). This may take a moment...")
        }
        
        print("🔄 Starting FIT file generation for \(adventure.records.count) records...")
        
        let startTime = Date()
        
        do {
            // Create encoder and encode
            // SwiftData models must be accessed on the main actor
            let encoder = MisfitFITEncoder()
            let fitData = try encoder.encode(adventure: adventure)
            let filename = encoder.suggestedFilename(for: adventure)
            
            // File I/O
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try fitData.write(to: fileURL)
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Generated FIT file: \(filename) (\(adventure.records.count) records) in \(String(format: "%.2f", duration))s")
            
            shareItem = FITFileItem(url: fileURL, filename: filename)
            
        } catch {
            print("❌ Failed to generate FIT file: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func cleanup() {
        guard let item = shareItem else { return }
        
        do {
            try FileManager.default.removeItem(at: item.url)
            print("🗑️ Cleaned up temp FIT file: \(item.filename)")
        } catch {
            print("⚠️ Failed to cleanup temp file: \(error)")
        }
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    let adventure: MisfitAdventure
    
    @State private var viewModel: ExportViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(StravaAuthenticationSession.self) private var stravaAuth
    
    init(adventure: MisfitAdventure) {
        self.adventure = adventure
        self._viewModel = State(initialValue: ExportViewModel(adventure: adventure))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Adventure summary
                VStack(spacing: 12) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    
                    Text(viewModel.adventure.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        if let distance = viewModel.adventure.totalDistance {
                            VStack(spacing: 4) {
                                Text(formatDistance(distance))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let duration = viewModel.adventure.endTime?.timeIntervalSince(viewModel.adventure.startTime) {
                            VStack(spacing: 4) {
                                Text(formatDuration(duration))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Text("\(viewModel.adventure.records.count.formatted()) data points")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // Actions
                VStack(spacing: 16) {
                    if viewModel.shareItem == nil {
                        // Generate button
                        Button {
                            Task {
                                await viewModel.generateFITFile()
                            }
                        } label: {
                            HStack {
                                if viewModel.isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "doc.badge.gearshape")
                                }
                                Text(viewModel.isGenerating ? "Generating FIT File..." : "Generate FIT File")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isGenerating ? Color.gray : Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isGenerating)
                        
                        if viewModel.adventure.records.count > 5000 {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                Text("Large dataset - may take a moment to generate")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        // Show error if any
                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        
                    } else if let item = viewModel.shareItem {
                        // Success state - show export options
                        VStack(spacing: 12) {
                            Label("FIT file ready!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.headline)
                            
                            // Share link button
                            ShareLink(item: item, preview: SharePreview(item.filename, image: Image(systemName: "bicycle"))) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share FIT File")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                            
                            // Strava upload button if authenticated
                            if stravaAuth.isAuthenticated && !stravaAuth.isExpired {
                                Button {
                                    viewModel.showingStravaUpload = true
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.circle.fill")
                                        Text("Upload to Strava")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Export Adventure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // Clean up temp file when sheet disappears
                viewModel.cleanup()
            }
        }
        .sheet(isPresented: $viewModel.showingStravaUpload) {
            if let item = viewModel.shareItem {
                StravaUploadSheet(fitFileItem: item, adventure: viewModel.adventure)
            }
        }
    }
    
    private func formatDistance(_ miles: Double) -> String {
        if miles < 0.25 {
            let feet = miles * 5280
            return String(format: "%.0f ft", feet)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}


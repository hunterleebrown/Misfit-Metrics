//
//  MisfitAdventures.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import Foundation
import SwiftUI
import SwiftData

struct MisfitAdventures: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MisfitAdventure.startTime, order: .reverse) private var adventures: [MisfitAdventure]
    
    @State private var adventureToDelete: MisfitAdventure?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            ForEach(adventures) { adventure in
                AdventureRow(adventure: adventure)
            }
            .onDelete(perform: handleDelete)
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date and time
            Text(adventure.startTime.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            
            // Stats row
            HStack(spacing: 16) {
                if let distance = adventure.totalDistance {
                    Label(String(format: "%.1f mi", distance), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
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



//
//  Misfit_MetricsApp.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI
import SwiftData

@main
struct Misfit_MetricsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MisfitAdventure.self,
            MisfitRecord.self,
            StravaAthlete.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Dashboard()
                .onOpenURL { url in
                    // Handle deep link from Strava app
                    handleStravaCallback(url: url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleStravaCallback(url: URL) {
        // Check if this is a Strava callback URL
        // Expected format: misfit-metrics://www.hunterleebrown.com?code=...&state=test
        guard url.scheme == "misfit-metrics",
              let code = StravaAuthenticationSession.shared.getStravaCode(url: url) else {
            return
        }
        
        // Exchange the code for a token
        StravaAuthenticationSession.shared.fetchStravaToken(stravCode: code)
    }
}

//
//  HalfCircleHeartRateMeter.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI

struct HalfCircleHeartRateMeter: View {
    let heartRate: Double // 0 to 200 bpm
    
    private let minHeartRate: Double = 0
    private let maxHeartRate: Double = 200
    private let startAngle: Angle = .degrees(180) // Bottom (6 o'clock)
    private let totalDegrees: Double = 180 // Half circle sweep
    private let tickInterval: Double = 20
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = width * 0.45
            let center = CGPoint(x: width / 2, y: height)
            
            ZStack {
                if heartRate > 0 {
                    // Heart rate pie wedge (filled from center)
                    HalfPieWedge(
                        startAngle: startAngle,
                        endAngle: .degrees(startAngle.degrees + (heartRateRatio * totalDegrees))
                    )
                    .fill(Color("fairyRed"))
                    
                    // Tick marks
                    ForEach(0..<Int(maxHeartRate / tickInterval) + 1, id: \.self) { index in
                        let bpm = Double(index) * tickInterval
                        let angle = startAngle.degrees + (bpm / maxHeartRate) * totalDegrees
                        
                        TickMark(
                            angle: angle,
                            radius: radius,
                            center: center,
                            isLarge: true
                        )
                    }
                    
                    // Center heart rate value
                    VStack(spacing: 2) {
                        Text("\(Int(heartRate))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("bpm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: center.x, y: center.y - radius * 0.5)
                } else {
                    // Not available state
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: center.x, y: center.y - radius * 0.5)
                }
            }
        }
    }
    
    private var heartRateRatio: Double {
        min(max(heartRate / maxHeartRate, 0), 1)
    }
}

#Preview {
    VStack(spacing: 40) {
        HalfCircleHeartRateMeter(heartRate: 0)
            .frame(width: 300, height: 150)
        
        HalfCircleHeartRateMeter(heartRate: 60)
            .frame(width: 300, height: 150)
        
        HalfCircleHeartRateMeter(heartRate: 120)
            .frame(width: 300, height: 150)
        
        HalfCircleHeartRateMeter(heartRate: 180)
            .frame(width: 300, height: 150)
        
        HalfCircleHeartRateMeter(heartRate: 200)
            .frame(width: 300, height: 150)
    }
    .padding()
}

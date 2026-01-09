//
//  HeartRateMeter.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI

struct HeartRateMeter: View {
    let heartRate: Double // 0 to 200 bpm
    
    private let startAngle: Angle = .degrees(90) // Start at 6 o'clock (90° in canvas coordinates)
    private let totalDegrees: Double = 350 // Total sweep
    private let maxHeartRate: Double = 200
    private let tickInterval: Double = 20
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.4
            
            ZStack {
                if heartRate > 0 {
                    // Heart rate pie wedge (filled from center)
                    PieWedge(
                        startAngle: startAngle,
                        endAngle: .degrees(startAngle.degrees + (heartRateRatio * totalDegrees))
                    )
                    .fill(Color("fairyRed"))
                    .frame(width: radius * 2, height: radius * 2)
                    
                    // Tick marks
                    ForEach(0..<Int(maxHeartRate / tickInterval) + 1, id: \.self) { index in
                        let bpm = Double(index) * tickInterval
                        // Adjust angle to match the rotated circle (add 90° to align)
                        let angle = 90 + (bpm / maxHeartRate) * totalDegrees
                        
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
                        Image(systemName: "heart.fill")
                            .font(.caption)
                    }
                } else {
                    // Not available state
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private var heartRateRatio: Double {
        min(max(heartRate / maxHeartRate, 0), 1)
    }
}

#Preview {
    VStack(spacing: 40) {
        HeartRateMeter(heartRate: 0)
            .frame(width: 150, height: 150)
        
        HeartRateMeter(heartRate: 60)
            .frame(width: 150, height: 150)
        
        HeartRateMeter(heartRate: 120)
            .frame(width: 150, height: 150)
        
        HeartRateMeter(heartRate: 180)
            .frame(width: 150, height: 150)
        
        HeartRateMeter(heartRate: 200)
            .frame(width: 150, height: 150)
    }
    .padding()
}

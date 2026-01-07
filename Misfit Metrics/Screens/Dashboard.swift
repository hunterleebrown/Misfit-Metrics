//
//  Dashboard.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct Dashboard: View {
    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 10) {

//            Speedometer(speed: viewModel.speed)
//                .frame(width: 300, height: 300)
//                .padding()
            
            // Duration Timer
            Text(viewModel.formattedElapsedTime)
                .font(.system(size: 64, weight: .medium, design: .monospaced))
                .padding(.horizontal)

            HalfCircleSpeedometer(speed: viewModel.speed)
                .frame(width: 300, height: 150)
                .padding(.horizontal)

            HStack(spacing: 20) {
                PowerMeter(power: viewModel.power)
                    .frame(width: 150, height: 150)
                    .border(Color.white)

                Spacer()

                HeartRateMeter(heartRate: viewModel.heartRate)
                    .frame(width: 150, height: 150)
                    .border(Color.white)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            .padding(.horizontal)

            Spacer()
        }
        .overlay(alignment: .bottom) {
            TestControlOverlay(
                isRunning: viewModel.isTestRunning,
                onStartStop: {
                    viewModel.toggleTest()
                }
            )
            .padding()
        }
    }
}

struct TestControlOverlay: View {
    let isRunning: Bool
    let onStartStop: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onStartStop) {
                HStack {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    Text(isRunning ? "Stop Test" : "Start Test")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isRunning ? Color.red : Color.green)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            if isRunning {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Testing...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}

extension Dashboard {

    @Observable
    final class ViewModel {

        var speed: Double = 12.0
        var power: Double = 0.0
        var heartRate: Double = 0.0
        var isTestRunning: Bool = false
        var elapsedTime: TimeInterval = 0
        var text: String = "Hello, World!"
        
        private var testTask: Task<Void, Never>?
        private var timerTask: Task<Void, Never>?
        private var startTime: Date?
        
        var formattedElapsedTime: String {
            let hours = Int(elapsedTime) / 3600
            let minutes = Int(elapsedTime) / 60 % 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        
        func toggleTest() {
            if isTestRunning {
                stopTest()
            } else {
                startTest()
            }
        }
        
        private func startTest() {
            isTestRunning = true
            startTime = Date()
            elapsedTime = 0
            
            // Timer task to update elapsed time
            timerTask = Task { @MainActor in
                while !Task.isCancelled && isTestRunning {
                    if let startTime = startTime {
                        elapsedTime = Date().timeIntervalSince(startTime)
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
            
            // Speed test task
            testTask = Task { @MainActor in
                while !Task.isCancelled && isTestRunning {
                    // Random speed change: ±1 or ±2
                    let changes = [1.0, -1.0, 2.0, -2.0]
                    let randomChange = changes.randomElement() ?? 0
                    
                    // Apply change and clamp between 0 and 35
                    speed = max(0, min(35, speed + randomChange))
                    
                    // Random power change: ±10 to ±50 watts
                    let powerChanges = [10.0, -10.0, 20.0, -20.0, 30.0, -30.0, 50.0, -50.0]
                    let randomPowerChange = powerChanges.randomElement() ?? 0
                    
                    // Apply change and clamp between 0 and 999
                    power = max(0, min(999, power + randomPowerChange))
                    
                    // Random heart rate change: ±1 to ±5 bpm
                    let heartRateChanges = [1.0, -1.0, 2.0, -2.0, 3.0, -3.0, 5.0, -5.0]
                    let randomHeartRateChange = heartRateChanges.randomElement() ?? 0
                    
                    // Apply change and clamp between 0 and 200
                    heartRate = max(0, min(200, heartRate + randomHeartRateChange))
                    
                    // Wait for 1 second
                    try? await Task.sleep(for: .seconds(0.25))
                }
            }
        }
        
        private func stopTest() {
            isTestRunning = false
            testTask?.cancel()
            testTask = nil
            timerTask?.cancel()
            timerTask = nil
        }
        
        deinit {
            testTask?.cancel()
            timerTask?.cancel()
        }
    }
}

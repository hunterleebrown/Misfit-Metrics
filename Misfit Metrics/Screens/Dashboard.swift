//
//  Dashboard.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct Dashboard: View {
    @State private var viewModel = ViewModel()
    @State private var showingHeartRateMonitor = false
    @State private var showingPowerMonitor = false

    var body: some View {
        VStack(spacing: 10) {

            // Duration Timer with Monitor Buttons
            HStack(alignment: .center, spacing: 16) {
                Button {
                    showingPowerMonitor = true
                } label: {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title)
                        .foregroundStyle(viewModel.powerMonitor.isConnected ? Color.green : Color("fairyRed"))
                }
                .buttonStyle(.plain)
                
                Text(viewModel.formattedElapsedTime)
                    .font(.system(size: 45, weight: .medium, design: .monospaced))

                Button {
                    showingHeartRateMonitor = true
                } label: {
                    Image(systemName: "heart.circle.fill")
                        .font(.title)
                        .foregroundStyle(viewModel.heartRateMonitor.isConnected ? Color.green : Color("fairyRed"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            // Top meter (half circle)
            Group {
                switch viewModel.layout {
                case .A:
                    HalfCircleSpeedometer(speed: viewModel.speed)
                case .B:
                    HalfCirclePowerMeter(power: viewModel.power)
                case .C:
                    HalfCircleHeartRateMeter(heartRate: viewModel.heartRate)
                }
            }
            .frame(width: 300, height: 150)
            .padding(.horizontal)
            .transition(.opacity.combined(with: .scale))

            // Bottom meters (two circles)
            HStack(spacing: 20) {
                Group {
                    switch viewModel.layout {
                    case .A:
                        PowerMeter(power: viewModel.power)
                    case .B:
                        HeartRateMeter(heartRate: viewModel.heartRate)
                    case .C:
                        Speedometer(speed: viewModel.speed)
                    }
                }
                .frame(width: 150, height: 150)
                .transition(.opacity.combined(with: .scale))

                Button {
                    viewModel.rotateMeters()
                } label: {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(Color("fairyRed"))
                        .fixedSize()
                        .padding(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("fairyRed"), lineWidth: 1)
                        }
                }

                Group {
                    switch viewModel.layout {
                    case .A:
                        HeartRateMeter(heartRate: viewModel.heartRate)
                    case .B:
                        Speedometer(speed: viewModel.speed)
                    case .C:
                        PowerMeter(power: viewModel.power)
                    }
                }
                .frame(width: 150, height: 150)
                .transition(.opacity.combined(with: .scale))

            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
            .padding(.horizontal)


            Group {
                VStack(alignment: .center) {
                    Text("\(Int(viewModel.cadence))")
                        .font(.system(size: 32, weight: .bold))
                    Text("RPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)


            Spacer()
        }
        .overlay(alignment: .bottom) {
            ControlPanel(
                isRunning: viewModel.isTestRunning,
                onStartPause: {
                    viewModel.toggleTest()
                },
                onReset: {
                    viewModel.reset()
                }
            )
            .padding()
        }
        .sheet(isPresented: $showingHeartRateMonitor) {
            HeartRateMonitorView(heartRateMonitor: viewModel.heartRateMonitor)
        }
        .sheet(isPresented: $showingPowerMonitor) {
            PowerMonitorView(powerMonitor: viewModel.powerMonitor)
        }
    }
}

struct ControlPanel: View {
    let isRunning: Bool
    let onStartPause: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onStartPause) {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                }
                .font(.title)
                .foregroundStyle(Color("fairyRed"))
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button(action: onReset) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                }
                .font(.title)
                .foregroundStyle(Color("fairyRed"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

extension Dashboard {

    enum MeterLayout {
        case A
        case B
        case C
    }

    @Observable
    final class ViewModel {

        var layout: MeterLayout = .A
        
        let motionManager = MotionManager()
        let heartRateMonitor = HeartRateMonitor()
        let powerMonitor = PowerMonitor()

        var cadence: Double = 0.0
        var speed: Double = 0.0
        var power: Double = 0.0
        var heartRate: Double = 0.0
        var isTestRunning: Bool = false
        var elapsedTime: TimeInterval = 0
        var text: String = "Hello, World!"
        
        private var testTask: Task<Void, Never>?
        private var timerTask: Task<Void, Never>?
        private var heartRateTask: Task<Void, Never>?
        private var powerTask: Task<Void, Never>?
        private var startTime: Date?
        private var pausedTime: TimeInterval = 0
        
        init() {
            // Start monitoring heart rate immediately
            startHeartRateMonitoring()
            // Start monitoring power immediately
            startPowerMonitoring()
        }
        
        var formattedElapsedTime: String {
            let hours = Int(elapsedTime) / 3600
            let minutes = Int(elapsedTime) / 60 % 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        
        func toggleTest() {
            if isTestRunning {
                pauseTest()
            } else {
                startTest()
            }
        }
        
        func reset() {
            stopTest()
            motionManager.stopTracking()
            speed = 0.0
            power = 0.0
            // Don't reset heart rate or power - keep showing live data from monitors
            elapsedTime = 0
            pausedTime = 0
            startTime = nil
            if !powerMonitor.isConnected {
                power = 0.0
            }
            if !heartRateMonitor.isConnected {
                heartRate = 0.0
            }
        }

        func rotateMeters() {
            withAnimation(.easeInOut(duration: 1.0)) {
                switch layout {
                case .A:
                    layout = .B
                case .B:
                    layout = .C
                case .C:
                    layout = .A
                }
            }
        }
        
        // Continuous heart rate monitoring (independent of test running state)
        private func startHeartRateMonitoring() {
            heartRateTask = Task { @MainActor in
                while !Task.isCancelled {
                    // Always update heart rate from monitor if available
                    if heartRateMonitor.heartRate > 0 {
                        heartRate = heartRateMonitor.heartRate
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        
        // Continuous power monitoring (independent of test running state)
        private func startPowerMonitoring() {
            powerTask = Task { @MainActor in
                while !Task.isCancelled {
                    // Always update power from monitor if available and connected
                    if powerMonitor.isConnected {
                        // Check if cadence should timeout and reset to 0
                        powerMonitor.checkCadenceTimeout()
                        
                        // Use 3-second average power
                        power = powerMonitor.threeSecondPower
                        cadence = powerMonitor.cadence
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }

        private func startTest() {
            isTestRunning = true
            
            // Start motion tracking
            motionManager.startTracking()
            
            if startTime == nil {
                // First time starting
                startTime = Date()
                elapsedTime = 0
                pausedTime = 0
            } else {
                // Resuming from pause
                startTime = Date().addingTimeInterval(-pausedTime)
            }
            
            // Timer task to update elapsed time
            timerTask = Task { @MainActor in
                while !Task.isCancelled && isTestRunning {
                    if let startTime = startTime {
                        elapsedTime = Date().timeIntervalSince(startTime)
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
            
            // Speed and power test task
            testTask = Task { @MainActor in
                while !Task.isCancelled && isTestRunning {
                    // Use real speed from motion manager
                    speed = motionManager.speed
                    
                    // Heart rate is now handled by the continuous monitoring task
                    
                    // Only generate random power if not connected to a real power meter
                    if !powerMonitor.isConnected {
                        // Random power change: ±10 to ±50 watts
                        let powerChanges = [10.0, -10.0, 20.0, -20.0, 30.0, -30.0, 50.0, -50.0]
                        let randomPowerChange = powerChanges.randomElement() ?? 0
                        
                        // Apply change and clamp between 0 and 999
                        power = max(0, min(999, power + randomPowerChange))
                    }
                    // If connected to power meter, power is handled by startPowerMonitoring()
                    
                    // Wait for 0.25 seconds
                    try? await Task.sleep(for: .seconds(0.25))
                }
            }
        }
        
        private func pauseTest() {
            isTestRunning = false
            pausedTime = elapsedTime
            motionManager.stopTracking()
            testTask?.cancel()
            testTask = nil
            timerTask?.cancel()
            timerTask = nil
        }
        
        private func stopTest() {
            isTestRunning = false
            motionManager.stopTracking()
            testTask?.cancel()
            testTask = nil
            timerTask?.cancel()
            timerTask = nil
        }
        
        deinit {
            testTask?.cancel()
            timerTask?.cancel()
            heartRateTask?.cancel()
            powerTask?.cancel()
        }
    }
}

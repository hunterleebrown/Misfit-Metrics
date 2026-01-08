//
//  Motion.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import CoreLocation
import CoreMotion
import SwiftUI

@Observable
class MotionManager: NSObject {
    private var locationManager = CLLocationManager()
    private var motionManager = CMMotionManager()
    var speed: Double = 0.0
    var distance: Double = 0.0 // in meters
    var currentElevation: Double = 0.0 // in meters
    var gainedElevation: Double = 0.0 // in meters
    private var lastLocation: CLLocation?
    private var isTracking: Bool = false
    
    // Computed property for distance in miles
    var distanceInMiles: Double {
        Measurement(value: distance, unit: UnitLength.meters)
            .converted(to: .miles)
            .value
    }
    
    // Computed property for current elevation in feet
    var currentElevationInFeet: Double {
        Measurement(value: currentElevation, unit: UnitLength.meters)
            .converted(to: .feet)
            .value
    }
    
    // Computed property for gained elevation in feet
    var gainedElevationInFeet: Double {
        Measurement(value: gainedElevation, unit: UnitLength.meters)
            .converted(to: .feet)
            .value
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startTracking() {
        isTracking = true
        requestMotionPermission()
        locationManager.startUpdatingLocation()
        motionManager.startAccelerometerUpdates()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
    }
    
    func resetTracking() {
        distance = 0.0
        gainedElevation = 0.0
        lastLocation = nil
    }

    func requestMotionPermission() {
        if #available(iOS 14.0, *) {
            CMMotionActivityManager().queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
                if let error = error {
                    print("Motion permission required: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension MotionManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Only accumulate distance and elevation when actively tracking
        if isTracking, let lastLoc = lastLocation {
            // Calculate distance traveled
            let distanceDelta = newLocation.distance(from: lastLoc)
            distance += distanceDelta
            
            // Calculate elevation gain (only positive changes)
            let elevationDelta = newLocation.altitude - lastLoc.altitude
            if elevationDelta > 0 {
                gainedElevation += elevationDelta
            }
        }

        // Always update current elevation and speed (even when paused)
        currentElevation = newLocation.altitude
        
        // Update speed
        speed = Measurement(value: newLocation.speed, unit: UnitSpeed.metersPerSecond)
            .converted(to: .milesPerHour)
            .value

        // Update last location only when tracking
        if isTracking {
            lastLocation = newLocation
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location permission denied.")
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
}

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
    var distance: Double = 0.0
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startTracking() {
        requestMotionPermission()
        locationManager.startUpdatingLocation()
        motionManager.startAccelerometerUpdates()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
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

        if let lastLoc = lastLocation {
            let distanceDelta = newLocation.distance(from: lastLoc)
            distance += distanceDelta
        }

        speed = Measurement(value: newLocation.speed, unit: UnitSpeed.metersPerSecond)
            .converted(to: .milesPerHour)
            .value

        lastLocation = newLocation
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

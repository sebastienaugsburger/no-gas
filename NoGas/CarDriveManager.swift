//
//  CarDriveManager.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/26/25.
//

import SwiftUI
import CoreLocation
import SwiftData
import MapKit

class DriveManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    //@Published var isRecording = false
    @Published var isRecording = false
    @Published var currentDrive: Drive?
    @Published var mostRecentDrive: Drive?
    @Published var userLocations: [CLLocationCoordinate2D] = []
    @Published var hasCurrentLocation: Bool = false
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    @Published var speedMetersPerHour: Double = 0.0
    @Published var altitude: Double = 0
    @Published var elevationClimbed: Double = 0
    //@Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        // Request when-in-use location authorization
        self.locationManager.requestWhenInUseAuthorization()
        /* Enable the app to collect location updates while it's in the background */
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        /* Set activity type for Core Location so that Core Location
        makes small adjustments to the reported location to match known roads */
        self.locationManager.activityType = .automotiveNavigation
        //self.locationManager.startUpdatingLocation()
        print("drive manager init")
    }
    
    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    func startRecording() {
        self.currentDrive = Drive(startTime: Date())
        self.isRecording = true
        self.lastLocation = nil
    }
    
    func stopRecording(context: ModelContext, activityPreviewImageWidth: CGFloat, activityPreviewImageHeight: CGFloat) {
        guard let drive = self.currentDrive else { return }
        self.mostRecentDrive = nil
        drive.endTime = Date()
        self.isRecording = false
        if drive.locations.count > 1 {
            guard let firstLocation =  drive.orderedLocations.first else { return }
            
            var previousAlt: Double = firstLocation.altitude
            
            for location in drive.orderedLocations {
                let altDiff = location.altitude - previousAlt
                if altDiff >= 1.0 || altDiff <= -1.0 {
                    if altDiff >= 1.0 {
                        drive.elevation += altDiff
                    }
                    previousAlt = location.altitude
                }
            }
            
            let size = CGSize(width: activityPreviewImageWidth, height: activityPreviewImageHeight)
            
            let coordinates = drive.orderedLocations.map {
                return CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            
            let generator = MapSnapshotGenerator()
            
            generator.generateSnapshot(from: coordinates, size: size) { data in
                drive.tripPreviewImageData = data
                context.insert(drive)
                do {
                    try context.save()
                } catch {
                    print("Failed to save context: \(error)")
                }
                DispatchQueue.main.async {
                    self.mostRecentDrive = drive
                    self.currentDrive = nil
                }
            }
        }
        
        
    }
    
    // Core Location provides location updates to the location manager’s delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location manager did update location")
        guard let newLocation = locations.last else { return }
        let altitude = newLocation.altitude
        let latitude = newLocation.coordinate.latitude
        let longitude = newLocation.coordinate.longitude
        self.hasCurrentLocation = true
        self.userLocations.append(newLocation.coordinate)
        let newCreatedAt = newLocation.timestamp
        
        if let last = lastLocation {
            let oldCreatedAt = last.timestamp
            let secondsInterval = newCreatedAt.secondsIntervalSinceOldDate(oldCreatedAt)
            let distance = last.distance(from: newLocation)
            self.currentDrive?.distance += distance
            let speedMetersPerHour = (distance / Double(secondsInterval)) * 3600 / 1609.34
            if isRecording {
                let driveLocation = DriveLocation(latitude: latitude, longitude: longitude, createdAt: newCreatedAt, speedMetersPerHour: speedMetersPerHour, altitude: altitude)
                
                self.currentDrive?.locations.append(driveLocation)
            }
            self.speedMetersPerHour = speedMetersPerHour
            self.altitude = altitude
        }
        
        self.lastLocation = newLocation
    }
    
    
}


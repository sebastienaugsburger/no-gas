//
//  CarDriveManager.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/26/25.
//

import SwiftUI
import CoreLocation
import SwiftData

@Model
class DriveLocation {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

@Model
class Drive: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date?
    var distance: Double = 0.0 // meters
    @Relationship(deleteRule: .cascade) var locations: [DriveLocation] = []
    
    init(startTime: Date) {
        self.startTime = startTime
    }
}

class DriveManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isRecording = false
    @Published var currentDrive: Drive?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var hasCurrentLocation: Bool = false
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        // Request when-in-use location authorization
        self.locationManager.requestWhenInUseAuthorization()
        /* Enable the app to collect location updates while it's in the background */
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        // Set location accuracy value
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer //kCLLocationAccuracyBestForNavigation
        /* Set activity type for Core Location so that Core Location
        makes small adjustments to the reported location to match known roads */
        self.locationManager.activityType = .automotiveNavigation
        self.locationManager.startUpdatingLocation()
    }
    
    func startRecording() {
        self.currentDrive = Drive(startTime: Date())
        self.isRecording = true
        self.lastLocation = nil
    }
    
    func stopRecording(context: ModelContext) {
        guard let drive = currentDrive else { return }
        drive.endTime = Date()
        self.isRecording = false
        //locationManager.stopUpdatingLocation()
        if drive.locations.count > 1 {
            context.insert(drive)
        }
        self.currentDrive = nil
    }
    
    // Core Location provides location updates to the location manager’s delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location manager did update location")
        
        guard let newLocation = locations.last else { return }
        //DispatchQueue.main.async {
            self.hasCurrentLocation = true
            self.currentLocation = newLocation.coordinate
        //}
        
        if isRecording {
            if let last = lastLocation {
                let distance = last.distance(from: newLocation)
                //DispatchQueue.main.async {
                    self.currentDrive?.distance += distance
                //}
            }
            
            let latitude = newLocation.coordinate.latitude
            let longitude = newLocation.coordinate.longitude
            
            let driveLocation = DriveLocation(latitude: latitude, longitude: longitude)
            
            //DispatchQueue.main.async {
                self.currentDrive?.locations.append(driveLocation)
            //}
            
            self.lastLocation = newLocation
            
            print("Updated location")
        }
    }
}


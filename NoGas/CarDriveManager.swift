//
//  CarDriveManager.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/26/25.
//

import SwiftUI
import CoreLocation
import SwiftData

struct MonthCard: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let date: Date
    
    init(name: String, date: Date) {
        self.name = name
        self.date = date
    }
}

@Model
class DriveLocation {
    var latitude: Double
    var longitude: Double
    var createdAt: Date = Date.now
    
    init(latitude: Double, longitude: Double, createdAt: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}

@Model
class Drive: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date?
    var distance: Double = 0.0 // meters
    var fuelValue: Double = 0.0
    @Relationship(deleteRule: .cascade) var locations: [DriveLocation] = []
    
    var startTimeStr: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy h:mma"
        return dateFormatter.string(from: startTime)
    }
    
    var absFuelValue: Double {
        abs(fuelValue)
    }
    
    var orderedLocations: [DriveLocation] {
        locations.sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    var miles: Double {
        distance / 1609.34
    }
    
    var hrCount: Int {
        let startTime = startTime
        let endTime = endTime ?? .now
        
        var hrCount = 0
        if let hour = Calendar.current.dateComponents([.hour], from: startTime, to: endTime).hour {
            hrCount = hour % 60
        }
        return hrCount
    }
    
    var minCount: Int {
        let startTime = startTime
        let endTime = endTime ?? .now
        
        var minCount = 0
        if let minute = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute {
            minCount = minute % 60
        }
        return minCount
    }
    
    var secCount: Int {
        let startTime = startTime
        let endTime = endTime ?? .now
        
        var secCount = 0
        if let second = Calendar.current.dateComponents([.second], from: startTime, to: endTime).second {
            secCount = second % 60
        }
        return secCount
    }
    
    var secCountTotal: Int {
        let startTime = startTime
        let endTime = endTime ?? .now
        
        var secCount = 0
        if let second = Calendar.current.dateComponents([.second], from: startTime, to: endTime).second {
            secCount = second
        }
        return secCount
    }
    
    var milesPerHour: Double {
        let metersPerSec = (distance) / Double(secCountTotal)
        let metersPerHour = metersPerSec * 3600
        let milesPerHour = metersPerHour / 1609.34
        return milesPerHour
    }
    
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
        /* Set activity type for Core Location so that Core Location
        makes small adjustments to the reported location to match known roads */
        self.locationManager.activityType = .automotiveNavigation
        self.locationManager.startUpdatingLocation()
        print("drive manager init")
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
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
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
        guard let createdAt = locations.last?.timestamp else { return }
        
        if isRecording {
            if let last = lastLocation {
                let distance = last.distance(from: newLocation)
                //DispatchQueue.main.async {
                    self.currentDrive?.distance += distance
                //}
            }
            
            let latitude = newLocation.coordinate.latitude
            let longitude = newLocation.coordinate.longitude
            let driveLocation = DriveLocation(latitude: latitude, longitude: longitude, createdAt: createdAt)
            
            //DispatchQueue.main.async {
                self.currentDrive?.locations.append(driveLocation)
            //}
            
            self.lastLocation = newLocation
            
            print("Updated location")
        }
    }
}


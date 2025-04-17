//
//  Models.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 4/15/25.
//

import Foundation
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
    var speedMetersPerHour: Double = 0.0
    var altitude: Double = 0.0
    
    init(latitude: Double, longitude: Double, createdAt: Date, speedMetersPerHour: Double, altitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.speedMetersPerHour = speedMetersPerHour
        self.altitude = altitude
    }
}

@Model
class Drive: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date?
    var distance: Double = 0.0 // meters
    var fuelValue: Double = 0.0
    var tripPreviewImageData: Data? = nil
    var elevation: Double = 0.0
    @Relationship(deleteRule: .cascade) var locations: [DriveLocation] = []
    
    var elevationClimbedInFeet: Double {
        Double(elevation) * 3.28084
    }
    
    var startTimeStr: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MMM d, h:mm a"
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

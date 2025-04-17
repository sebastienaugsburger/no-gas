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
    @Published var currentLocation: CLLocationCoordinate2D?
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
        
        guard let firstLocation =  drive.orderedLocations.first else { return }
        
        var previousAlt: Double = firstLocation.altitude
        
        for location in drive.orderedLocations {
            let altDiff = location.altitude - previousAlt
            if altDiff >= 1 || altDiff <= -1 {
                if altDiff >= 1 {
                    drive.elevation += altDiff
                }
                previousAlt = location.altitude
            }
        }
        
        Task {
            let data = await generateSnapshot(drive, activityPreviewImageWidth: activityPreviewImageWidth, activityPreviewImageHeight: activityPreviewImageHeight)
            drive.tripPreviewImageData = data
            if drive.locations.count > 1 {
                context.insert(drive)
                do {
                    try context.save()
                } catch {
                    print("Failed to save context: \(error)")
                }
                self.mostRecentDrive = drive
            }
        }
        
        self.currentDrive = nil
    }
    
    // Core Location provides location updates to the location manager’s delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location manager did update location")
        guard let newLocation = locations.last else { return }
        let altitude = newLocation.altitude
        let latitude = newLocation.coordinate.latitude
        let longitude = newLocation.coordinate.longitude
        self.hasCurrentLocation = true
        self.currentLocation = newLocation.coordinate
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
    
    func generateSnapshot(_ drive: Drive, activityPreviewImageWidth: CGFloat, activityPreviewImageHeight: CGFloat) async -> Data? {
        let coordinates = drive.orderedLocations.map {
            return CLLocation(latitude: $0.latitude, longitude: $0.longitude).coordinate
        }
        
        let options = MKMapSnapshotter.Options()
        //create a bounding box around your coordinate array.
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        var mapRect = polyline.boundingMapRect
        
        let xPadding = mapRect.size.width * -0.1
        let yPadding = mapRect.size.height * -0.1
        
        mapRect = mapRect.insetBy(dx: xPadding, dy: yPadding)
        
        options.mapRect = mapRect
        options.scale =  await UIScreen.main.scale
        options.size = CGSize(width: activityPreviewImageWidth, height: activityPreviewImageHeight)

        let snapshotter = MKMapSnapshotter(options: options)
        
        do {
            let imageSnapshot = try await snapshotter.start()
            
            if let inputImage = drawLineOnImage(imageSnapshot, options: options, coordinates: coordinates) {
                return inputImage.pngData()
            } else {
                print("Failed to draw line on image, no image returned.")
                return nil
            }
        } catch {
            print("Failed to get image snapshot for drive: \(error.localizedDescription)")
            return nil
        }
    }
    
    func drawLineOnImage(_ snapshot: MKMapSnapshotter.Snapshot, options: MKMapSnapshotter.Options, coordinates: [CLLocationCoordinate2D]) -> UIImage? {
        
        let image = snapshot.image
        let size = options.size
        let scale = options.traitCollection.displayScale
        // for Retina
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        // draw image into ui graphics image context
        image.draw(at: CGPoint.zero)
        
        // get the context for CoreGraphics
        //let context = UIGraphicsGetCurrentContext()
        
        let path = UIBezierPath()
        
        let points = coordinates.map { snapshot.point(for: $0) }
        
        let smoothedCoordinates = interpolateCatmullRom(points: points, numberOfPointsPerSegment: 10)
        
        if let firstPoint = smoothedCoordinates.first {
            path.move(to: firstPoint)
        }
        
        for point in smoothedCoordinates {
            path.addLine(to: point)
        }
        
        UIColor.accent.setStroke()
        
        path.lineWidth = 5
        path.stroke()
        
        let result  = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result != nil ? result : nil
    }
    
    // Function to interpolate points using Catmull-Rom spline
    func interpolateCatmullRom(points: [CGPoint], numberOfPointsPerSegment: Int) -> [CGPoint] {
        var smoothPoints: [CGPoint] = []
        
        // Make sure we have at least 4 points to start with
        guard points.count > 3 else { return points }
        
        for i in 1..<points.count - 2 {
            let p0 = points[i - 1]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = points[i + 2]
            
            for t in stride(from: 0.0, to: 1.0, by: 1.0 / CGFloat(numberOfPointsPerSegment)) {
                let x = interpolateCatmullRom(p0.x, p1.x, p2.x, p3.x, t: t)
                let y = interpolateCatmullRom(p0.y, p1.y, p2.y, p3.y, t: t)
                smoothPoints.append(CGPoint(x: x, y: y))
            }
        }
        
        return smoothPoints
    }

    // Catmull-Rom spline interpolation for a single dimension (X or Y)
    func interpolateCatmullRom(_ p0: CGFloat, _ p1: CGFloat, _ p2: CGFloat, _ p3: CGFloat, t: CGFloat) -> CGFloat {
        let t2 = t * t
        let t3 = t2 * t
        
        let v0 = (p2 - p0) * 0.5
        let v1 = (p3 - p1) * 0.5
        
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1
    }
}


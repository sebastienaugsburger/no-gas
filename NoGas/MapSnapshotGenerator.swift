//
//  MapSnapshotGenerator.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 4/19/25.
//

import Foundation
import MapKit

class MapSnapshotGenerator {
    func generateSnapshot(from coordinates: [CLLocationCoordinate2D], size: CGSize, completion: @escaping (Data?) -> Void) {
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        let dx = polyline.boundingMapRect.width * -0.1
        let dy = polyline.boundingMapRect.width * -0.2
        let paddedRect = polyline.boundingMapRect.insetBy(dx: dx, dy: dy)
        let region = MKCoordinateRegion(paddedRect)
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        //options.scale = UIScreen.main.scale
        options.mapType = .mutedStandard // looks cleaner, like Apple's Fitness previews
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }

            let mapImage = snapshot.image

            let finalImageData = UIGraphicsImageRenderer(size: size).pngData { context in
                // Draw base map
                mapImage.draw(at: .zero)
                
                let points = coordinates.map { coordinate in
                    snapshot.point(for: coordinate)
                }

                let testNumbers = [0, 1, 2, 3, 4]
                
                for num in testNumbers.dropFirst() {
                    print("\(num)")
                }

                //var previousPoint: CGPoint?
                
                let path = UIBezierPath()
                
                if let firstPoint = points.first {
                    path.move(to: firstPoint)
                }
                
                

                for point in points.dropFirst() {
                    path.addLine(to: point)
                    //previousPoint = point
                }
                
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                path.lineWidth = 5
                UIColor.accent.setStroke()
                path.stroke()
            }

            completion(finalImageData)
        }
    }
}


//
//  RecordDriveView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/26/25.
//

import SwiftUI
import MapKit

struct RecordDriveView: View {
    
    @EnvironmentObject var driveManager: DriveManager
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("metricSystem") var metricSystem: Bool = true
    @AppStorage("evCar") var evCar: Bool = true
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("mpg") var mpg: Int = 32
    @AppStorage("metricFuelPrice") var metricFuelPrice: Double = 7.00
    @AppStorage("kmpl") var kmpl: Int = 42
    //@AppStorage("fuelCostBalance") var fuelCostBalance: Double = 0.0
    //@AppStorage("milesTraveled") var milesTraveled: Double = 0.0
    //@AppStorage("driveCount") var driveCount: Int = 0
    
    @Binding var showRecordDriveView: Bool
    
    @State private var position: MapCameraPosition = .automatic
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    
    @State var isTimerRunning = false
    @State private var startTime =  Date()
    @State private var timerString = "00:00:00"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showButtons: Bool = true
    
    @State private var debounceWorkItem: DispatchWorkItem?
    
    var distanceMiString: String {
        let distanceInMeters = driveManager.currentDrive?.distance ?? 0
        let distanceInMiles = distanceInMeters / 1609.34
        return String(format: distanceInMiles >= 10 ? "%.0f":"%.1f", distanceInMiles)
    }
    
    var distanceKmString: String {
        let distanceInMeters = driveManager.currentDrive?.distance ?? 0
        let distanceInMiles = distanceInMeters / 1000.0
        return String(format: distanceInMiles >= 10 ? "%.0f":"%.1f", distanceInMiles)
    }
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            NavigationStack {
                VStack(spacing: 20) {
                    VStack (alignment: .leading, spacing: 20) {
                        ZStack(alignment: .top) {
                            Color(uiColor: .systemGray6)
                            DriveMapView(region: $region)
                                .onChange(of: driveManager.userLocations.count) {
                                    guard let lastCoord = driveManager.userLocations.last else { return }
                                    region.center = lastCoord
                                }
                            
                            HStack(alignment: .top) {
                                if driveManager.isRecording == false {
                                    Button {
                                        showRecordDriveView = false
                                    } label: {
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundStyle(.black)
                                            .frame(width: 50, height: 50)
                                            .background {
                                                Circle()
                                                    .fill(.white)
                                            }
                                    }
                                }
                                
                                Spacer()
                                VStack(spacing: 0) {
                                    
                                    if driveManager.speedMetersPerSecond > 0 && driveManager.speedMetersPerSecond < .infinity {
                                        if metricSystem {
                                            Text(String(format: "%.0f", driveManager.speedKilometersPerHour))
                                                .font(.system(size: 38, weight: .bold))
                                        } else {
                                            Text(String(format: "%.0f", driveManager.speedMilesPerHour))
                                                .font(.system(size: 38, weight: .bold))
                                            
                                        }
                                    } else  {
                                        Text("0")
                                            .font(.system(size: 38, weight: .bold))
                                    }
                                    
                                    Text(metricSystem ? "KMPH":"MPH")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(.black)
                                .frame(width: 75, height: 75)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.white)
                                }
                            }
                            .padding(.top, geo.safeAreaInsets.top + 20)
                            .padding(.horizontal)
                        }
                        .cornerRadius(20)
                        .environmentObject(driveManager)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 0) {
                                if metricSystem {
                                    Text(distanceKmString)
                                        .font(.title.bold())
                                    + Text("km")
                                        .font(.title3)
                                } else {
                                    Text(distanceMiString)
                                        .font(.title.bold())
                                    + Text("mi")
                                        .font(.title3)
                                }
                                Text("Distance")
                                    .foregroundStyle(.gray)
                                    //.font(.caption)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(timerString)
                                    .font(.title.bold())
                                    .onReceive(timer) { _ in
                                        if isTimerRunning {
                                            timerString = tripDurationString(current: .now, previous: startTime)
                                        }
                                    }
                                    .onAppear() {
                                        // no need for UI updates at startup
                                        stopTimer()
                                    }
                                Text("Duration")
                                    .foregroundStyle(.gray)
                                    //.font(.caption)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemGray6))
                    }
                    
                    if showButtons {
                        HStack(spacing: 10) {
                            // Start/Stop drive recording
                            Button {
                                
                                if driveManager.isRecording {
                                    self.showButtons = false
                                    if let drive = driveManager.currentDrive {
                                        // Imperial or metric for fuel cost calc
                                        if metricSystem {
                                            drive.fuelValue = (drive.distance / 1000.0)/Double(kmpl) * metricFuelPrice
                                        } else {
                                            drive.fuelValue = (drive.distance / 1609.34)/Double(mpg) * gasPrice
                                        }
                                        
                                        // Negative fuel cost for EV
                                        if evCar {
                                            drive.fuelValue = drive.fuelValue * -1
                                        }
                                    }
                                    self.driveManager.stopRecording(context: modelContext, activityPreviewImageWidth: viewWidth - 40, activityPreviewImageHeight: 200)
                                    self.showRecordDriveView = false
                                } else {
                                    self.driveManager.startRecording()
                                }
                                
                                if self.isTimerRunning {
                                    // stop UI updates
                                    self.stopTimer()
                                } else {
                                    
                                    self.startTime = Date()
                                    // start UI updates
                                    self.startTimer()
                                }
                                
                                isTimerRunning.toggle()
                            
                            } label: {
                                Text(driveManager.isRecording ? "End drive" : "Start drive")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundColor(driveManager.isRecording ? Color.white:Color.black)
                                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                                    .background{
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(driveManager.isRecording ? Color.red : Color.accentColor)
                                    }
                            }
                        }
                        .padding([.bottom, .horizontal])
                    } else {
                        Color.clear
                            .frame(height: 55)
                            .padding([.bottom, .horizontal])
                    }
                }
                .ignoresSafeArea(edges: [.top])
                .onAppear {
                    guard let lastCoord = driveManager.userLocations.last else { return }
                    region.center = lastCoord
                }
            }
        }
    }
    
    func stopTimer() {
        self.timer.upstream.connect().cancel()
        timerString = "00:00:00"
    }
        
    func startTimer() {
        self.timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    }
    
    func tripDurationString(current: Date, previous: Date) -> String {
        var hrStr = ""
        var minStr = ""
        var secStr = ""
        
        if let hour = Calendar.current.dateComponents([.hour], from: previous, to: current).hour {
            hrStr = hour > 9 ? "\(hour)":"0\(hour)"
        }
        
        if let minute = Calendar.current.dateComponents([.minute], from: previous, to: current).minute {
            let minCount = minute % 60
            minStr = minCount > 9 ? "\(minCount)":"0\(minCount)"
        }
        
        if let second = Calendar.current.dateComponents([.second], from: previous, to: current).second {
            let secCount = second % 60
            secStr = secCount > 9 ? "\(secCount)":"0\(secCount)"
        }

        return "\(hrStr):\(minStr):\(secStr)"
    }
}

#Preview {
    RecordDriveView(showRecordDriveView: .constant(true))
}

struct DriveMapView: View {
    @EnvironmentObject private var driveManager: DriveManager
    @Binding var region: MKCoordinateRegion
    @State var updateLocation: Bool = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RecordDriveMapViewRepresentable(driveManager: driveManager, region: $region, updateLocation: $updateLocation)
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        updateLocation = false
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        updateLocation = false
                    }
            )
            
            if updateLocation == false {
                Button {
                    updateLocation = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 50, height: 50)
                            .shadow(radius: 5, y: 5)
                        
                        Image(systemName: "location.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 23, height: 23)
                            .foregroundStyle(.black)
                    }
                }
                .padding(.leading)
                .padding(.bottom, 40)
            }
        }
    }
}


struct ReviewDriveMapViewRepresentable: UIViewRepresentable {
    let driveLocations: [DriveLocation]
    //@Binding var region: MKCoordinateRegion
    //@Binding var updateLocation: Bool

    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        //mapView.showsUserLocation = true
        //mapView.userTrackingMode = .follow // Automatically follows user
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
//        if updateLocation {
//            uiView.setRegion(region, animated: true)
//        }
        updatePolyline(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ReviewDriveMapViewRepresentable

        init(_ parent: ReviewDriveMapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.accent
                renderer.lineWidth = 3.0
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
    
    private func updatePolyline(_ mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        //if let driveLocations = driveManager.currentDrive?.locations {
            var locations = [CLLocation]()
            for driveLocation in driveLocations {
                let clLocation = CLLocation(latitude: driveLocation.latitude, longitude: driveLocation.longitude)
                locations.append(clLocation)
            }
            if locations.count > 1 {
                let coordinates = locations.map { $0.coordinate }
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                mapView.addOverlay(polyline)
                mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
               
            }
        //}
    }
}

struct RecordDriveMapViewRepresentable: UIViewRepresentable {
    @ObservedObject var driveManager: DriveManager
    @Binding var region: MKCoordinateRegion
    @Binding var updateLocation: Bool

    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: true)
        //mapView.userTrackingMode = .follow // Automatically follows user
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if updateLocation {
            uiView.setRegion(region, animated: true)
        }
        updatePolyline(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RecordDriveMapViewRepresentable

        init(_ parent: RecordDriveMapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.accent
                renderer.lineWidth = 3.0
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
    
    private func updatePolyline(_ mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        if let driveLocations = driveManager.currentDrive?.orderedLocations {
            var locations = [CLLocation]()
            for driveLocation in driveLocations {
                let clLocation = CLLocation(latitude: driveLocation.latitude, longitude: driveLocation.longitude)
                locations.append(clLocation)
            }
            if locations.count > 1 {
                let coordinates = locations.map { $0.coordinate }
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                mapView.addOverlay(polyline)
                //mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
            }
        }
    }
}

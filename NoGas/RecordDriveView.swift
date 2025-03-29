//
//  RecordDriveView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/26/25.
//

import SwiftUI
import MapKit

struct RecordDriveView: View {
    @StateObject private var driveManager = DriveManager()
    @Environment(\.modelContext) private var modelContext
    
    @Binding var showRecordDriveView: Bool
    
    @State private var position: MapCameraPosition = .automatic
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    
    @State var isTimerRunning = false
    @State private var startTime =  Date()
    @State private var timerString = "0.00"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showButtons: Bool = true
    
    var distanceString: String {
        let distanceInMeters = driveManager.currentDrive?.distance ?? 0
        let distanceInMiles = distanceInMeters / 1609.34
        return String(format: "%.2f", distanceInMiles)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack (alignment: .leading, spacing: 20) {
                    ZStack {
                        Color(uiColor: .systemGray6)
                        //Map(position: .constant(.region(region)), interactionModes: .all)
                        DriveMapView(region: $region)
                            
                    }
                    
                    .cornerRadius(20)
                    .environmentObject(driveManager)
                    .onChange(of: driveManager.hasCurrentLocation) { newLocation, oldLocation in
                        guard let cuLocation = driveManager.currentLocation else { return }
                        region.center = cuLocation
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(timerString)
                                .font(.title.bold())
                                .onReceive(timer) { _ in
                                    if isTimerRunning {
                                        timerString = String(format: "%.0fs", (Date().timeIntervalSince(startTime)))
                                    }
                                }
                                .onAppear() {
                                    // no need for UI updates at startup
                                    stopTimer()
                                }
                            Text("Duration")
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(distanceString)
                                .font(.title.bold())
                            Text("Distance (Miles)")
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                if showButtons {
                    HStack(spacing: 10) {
                        
                        if driveManager.isRecording == false {
                            Button {
                                showRecordDriveView = false
                            } label: {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.white)
                                    .frame(width: 55, height: 55)
                                    .background {
                                        Circle()
                                            .fill(Color(uiColor: .systemGray5))
                                    }
                            }
                        }
                        
                        // Start/Stop drive recording
                        Button {
                            if driveManager.isRecording {
                                self.showButtons = false
                                self.driveManager.stopRecording(context: modelContext)
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
                            Label(driveManager.isRecording ? "End drive" : "Start drive", systemImage: "steeringwheel")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55)
                                .background(driveManager.isRecording ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .disabled(driveManager.currentLocation == nil)
                    }
                    .padding([.bottom, .horizontal])
                } else {
                    Color.clear
                        .frame(height: 55)
                        .padding([.bottom, .horizontal])
                }
            }
            .ignoresSafeArea(edges: [.top])
        }
    }
    
    func stopTimer() {
        self.timer.upstream.connect().cancel()
        timerString = "0.00"
    }
        
    func startTimer() {
        self.timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
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
        ZStack(alignment: .bottomTrailing) {
            
                MapViewRepresentable(region: $region, updateLocation: $updateLocation)
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
                    .onChange(of: driveManager.currentDrive?.locations.last) { newLocation, oldLocation in
                        if let location = newLocation {
                            region.center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        }
                    }
                    
            
                if updateLocation == false {
                    Button {
                        updateLocation = true
                    } label: {
                        Image(systemName: "location.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 23, height: 23)
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 50)
                            .background {
                                Circle()
                                    .fill(Color.white)
                            }
                    }
                    .padding()
                }
            
        }
    }
}


struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var updateLocation: Bool

    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        //mapView.userTrackingMode = .follow // Automatically follows user
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if updateLocation {
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
    }
}

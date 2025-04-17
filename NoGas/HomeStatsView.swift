//
//  HomeStatsView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/25/25.
//

import SwiftUI
import SwiftData
import MapKit

struct DataService {
    static func fetchDrivesInMonth(in context: ModelContext, for date: Date) -> [Drive] {
        print("called fetchDrivesInMonth()")
        var drives = [Drive]()
        
        let startOfMonth = date.startDateOfMonth
        let endOfMonth = Calendar.current.startOfDay(for: startOfMonth.adding(.month, value: 1))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy h:mma"
        
        print("start of month: \(dateFormatter.string(from: startOfMonth))")
        print("end of month: \(dateFormatter.string(from: endOfMonth))")
            
        let predicate = #Predicate<Drive> { drive in
            drive.startTime >= startOfMonth && drive.startTime < endOfMonth
        }
        
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        
        do {
            drives = try context.fetch(descriptor)
        } catch {
            print("failed to get drive items: \(error.localizedDescription)")
        }
        
        return drives
    }
    
    static func getOldestDriveItems(modelContext: ModelContext) -> [Drive] {
        var drives = [Drive]()
        
        var descriptor = FetchDescriptor<Drive>(
            
            //predicate: #Predicate<Drive> { true == true },
            sortBy: [SortDescriptor(\.startTime)]
        )
        descriptor.fetchLimit = 1 // retrieve only one object
        
        do {
            drives = try modelContext.fetch(descriptor)
        } catch {
            print("failed to get drive items: \(error.localizedDescription)")
        }
        
        return drives
    }
    
    static func getNewestDriveItems(modelContext: ModelContext) -> [Drive] {
        var drives = [Drive]()
        
        var descriptor = FetchDescriptor<Drive>(
            
            //predicate: #Predicate<Drive> { true == true },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1 // retrieve only one object
        
        do {
            drives = try modelContext.fetch(descriptor)
        } catch {
            print("failed to get drive items: \(error.localizedDescription)")
        }
        
        return drives
    }
}

struct HomeStatsView: View {
    
    @StateObject private var driveManager = DriveManager()
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("evCar") var evCar: Bool = true
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("mpg") var mpg: Int = 32
    
    @State private var selectedDrive: Drive?
    @State private var showRecordDrive: Bool = false
    @State var monthCards: [MonthCard] = []
    @State private var showMostRecentTripReviewView = false
    
//    var absFuelCostBalance: Double {
//        abs(fuelCostBalance)
//    }
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            NavigationStack {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            Button {
                                showRecordDrive = true
                            } label: {
                                Text("New trip")
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(minWidth: .zero, maxWidth: .infinity, minHeight: 60)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.accent)
                                    }
                            }
                            .fullScreenCover(isPresented: $showRecordDrive) {
                                RecordDriveView(showRecordDriveView: $showRecordDrive)
                                    .environmentObject(driveManager)
                                    .onAppear {
                                        self.driveManager.startUpdatingLocation()
                                    }
                                    .onDisappear {
                                        self.driveManager.stopUpdatingLocation()
                                        prepareSnapShotAndMonthsList()
                                    }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 20) {
//                                Group {
//                                    HStack(spacing: 10) {
//                                        VStack(alignment: .leading) {
//                                            Text("$")
//                                                .font(.title)
//                                                .foregroundStyle(fuelCostBalance > 0 ? Color.red:Color.green)
//                                            + Text(String(format: "%.2f", absFuelCostBalance))
//                                                .font(.title.bold())
//                                                .foregroundStyle(fuelCostBalance > 0 ? Color.red:Color.green)
//                                            Text("Total fuel cost")
//                                        }
//                                        .padding(.horizontal)
//                                        .frame(width: viewWidth/2 - 25, alignment: .leading)
//                                        .padding(.vertical)
//                                        .background {
//                                            RoundedRectangle(cornerRadius: 15)
//                                                .fill(Color(uiColor: UIColor.systemGray5))
//                                        }
//                                        
//                                        VStack(alignment: .leading) {
//                                            Text("\(milesTraveled, specifier: "%.2f")")
//                                                .font(.title.bold())
//                                            + Text("mi")
//                                                .font(.title3)
//                                            Text("Total distance")
//                                        }
//                                        .padding(.horizontal)
//                                        .frame(width: viewWidth/2 - 25, alignment: .leading)
//                                        .padding(.vertical)
//                                        .background {
//                                            RoundedRectangle(cornerRadius: 15)
//                                                .fill(Color(uiColor: UIColor.systemGray5))
//                                        }
//                                    }
//                                    .padding(.horizontal, 20)
//                                }
                                
                                Group {
                                    HStack(spacing: 10) {
                                        NavigationLink {
                                            EditGasPriceView(gasPrice: $gasPrice)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("$")
                                                        .font(.title)
                                                    + Text(String(format: "%.2f", gasPrice))
                                                        .font(.title.bold())
                                                    Text("Fuel price/gal.")
                                                        .foregroundStyle(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.gray)
                                            }
                                            .foregroundStyle(Color.primary)
                                            .padding(.horizontal)
                                            .frame(width: viewWidth/2 - 25, alignment: .leading)
                                            .padding(.vertical)
                                            .background {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(uiColor: UIColor.systemGray5))
                                            }
                                        }
                                        NavigationLink {
                                            EditMPGView(mpg: $mpg)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("\(mpg)")
                                                        .font(.title.bold())
                                                    Text("MPG")
                                                        .foregroundStyle(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.gray)
                                            }
                                            .foregroundStyle(Color.primary)
                                            .padding(.horizontal)
                                            .frame(width: viewWidth/2 - 25, alignment: .leading)
                                            .padding(.vertical)
                                            .background {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(uiColor: UIColor.systemGray5))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                Toggle("Electric Vehicle", isOn: $evCar)
                                    .bold()
                                    .tint(.accentColor)
                                    .frame(minWidth: .zero, maxWidth: .infinity, minHeight: 60)
                                    .padding(.horizontal)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(uiColor: .systemGray5))
                                    }
                                    .padding(.horizontal, 20)
                            }
                            
                            if let drive = self.driveManager.mostRecentDrive {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Most recent")
                                            .font(.title3.bold())
                                        Spacer()
                                    }
                                    
                                    DrivePreviewView(drive: drive, width: viewWidth, selectedDrive: $selectedDrive)
                                        .onTapGesture {
                                            self.showMostRecentTripReviewView = true
                                        }
                                        .navigationDestination(isPresented: $showMostRecentTripReviewView) {
                                            if let drive = self.driveManager.mostRecentDrive {
                                                ReviewDriveView(drive: drive)
                                            }
                                        }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Trips")
                                        .font(.title3.bold())
                                    Spacer()
                                }
                                
                                VStack(spacing: 20) {
                                    ForEach(monthCards) { card in
                                        NavigationLink(value: card) {
                                            Text(card.name)
                                                .bold()
                                                .foregroundStyle(.white)
                                                .padding(.horizontal)
                                                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(uiColor: .systemGray5))
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom)
                        }
                        .padding(.vertical)
                    }
                }
                .navigationDestination(for: MonthCard.self) { card in
                    MonthDriveHistoryView(card: card)
                }
                .alert(item: $selectedDrive) { drive in
                    Alert(
                        title: Text("Delete drive"),
                        message: Text("Are you sure you want to delete your drive from \(drive.startTime.formatted())?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteDrive(modelContext, drive: drive)
                        },
                        secondaryButton: .cancel()
                    )
                }
                .onAppear {
                    prepareSnapShotAndMonthsList()
                }
            }
        }
    }
    
    func prepareSnapShotAndMonthsList() {
        if let drive = DataService.getNewestDriveItems(modelContext: modelContext).first {
            self.driveManager.mostRecentDrive = drive
        }
        
        let oldestDrives = DataService.getOldestDriveItems(modelContext: modelContext)
        
        if let drive = oldestDrives.first {
            let firstDriveStartTime = drive.startTime
            var testDate: Date = firstDriveStartTime.startDateOfMonth
            //if let backedUpDate = Calendar.current.date(byAdding: .month, value: -3, to: testDate) {
                
            var monthCards: [MonthCard] = []
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
        
            while testDate <= Date() {
                let dateString = dateFormatter.string(from: testDate)
                let newMonthCard = MonthCard(name: dateString, date: testDate)
                monthCards.insert(newMonthCard, at: 0)
                testDate = testDate.adding(.month, value: 1)
            }
            
            self.monthCards = monthCards
            //}
        }
    }
    
    func deleteDrive(_ context: ModelContext, drive: Drive) {
        context.delete(drive)
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        self.driveManager.mostRecentDrive = nil
    }
}

#Preview {
    HomeStatsView()
}

struct DrivePreviewView: View {
    @Bindable var drive: Drive
    let width: CGFloat
    @Binding var selectedDrive: Drive?
    @State private var snapshotImageData: Data?
    
    var mapWidth: CGFloat {
        abs(width - 40)
    }
    
    var mapHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 15) {
                // Image drive route
                ZStack(alignment: .topTrailing) {
                    if let data = drive.tripPreviewImageData, let inputImage = UIImage(data: data) {
                        Image(uiImage: inputImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.white.opacity(0.001)
                            .scaledToFill()
                    }
                    
                    Button {
                        self.selectedDrive = drive
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background {
                                Circle()
                                    .fill(.regularMaterial)
                            }
                    }
                    .padding([.top, .trailing])
                }
                .frame(height: 200)
                
                // Drive stats
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("$")
                                .font(.title2)
                                .foregroundStyle(drive.fuelValue > 0 ? Color.red:Color.green)
                            + Text(String(format: "%.2f", drive.absFuelValue))
                                .font(.title2.bold())
                                .foregroundStyle(drive.fuelValue > 0 ? Color.red:Color.green)
                            Text("Fuel cost")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(drive.miles, specifier: "%.2f")")
                                .font(.title2.bold())
                            + Text("mi")
                                .font(.title3)
                            Text("Distance")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                if drive.hrCount > 0 {
                                    Text("\(drive.hrCount)")
                                        .font(.title2.bold())
                                    + Text("h")
                                        .font(.title3)
                                }
                                Text("\(drive.minCount)")
                                    .font(.title2.bold())
                                + Text("m")
                                    .font(.title3)
                                Text("\(drive.secCount)")
                                    .font(.title2.bold())
                                + Text("s")
                                    .font(.title3)
                            }
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(drive.milesPerHour, specifier: "%.2f")")
                                .font(.title2.bold())
                            + Text("mph")
                                .font(.title3)
                            Text("Avg. speed")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    
                        VStack(alignment: .leading, spacing: 0) {
                            Text(String(format: "%.0f", drive.elevationClimbedInFeet))
                                .font(.title2.bold())
                            + Text("ft")
                                .font(.title3)
                            Text("Elevation")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor.systemGray5))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Drive start time
            HStack {
                Text(drive.startTimeStr)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.gray)
                    //.shadow(color: .black, radius: 5)
                
                Spacer()
                
                
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
//        .task {
//            if snapshotImageData == nil {
//                print("calling generateSnapshot for drive")
//                drive.tripPreviewImageData = await generateSnapshot(drive, activityPreviewImageWidth: mapWidth, activityPreviewImageHeight: 200)
//            }
//            
////            if drive.elevation == 0 {
////                guard let firstLocation =  drive.orderedLocations.first else { return }
////                
////                var previousAlt: Double = firstLocation.altitude
////                
////                for location in drive.orderedLocations {
////                    let altDiff = location.altitude - previousAlt
////                    if altDiff > 0 {
////                        drive.elevation += altDiff
////                    }
////                    previousAlt = location.altitude
////                }
////            }
//        }
    }
    
//    func generateSnapshot(_ drive: Drive, activityPreviewImageWidth: CGFloat, activityPreviewImageHeight: CGFloat) async -> Data? {
//        let coordinates = drive.orderedLocations.map {
//            return CLLocation(latitude: $0.latitude, longitude: $0.longitude).coordinate
//        }
//        
//        let options = MKMapSnapshotter.Options()
//        //create a bounding box around your coordinate array.
//        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
//        
//        var mapRect = polyline.boundingMapRect
//        
//        let xPadding = mapRect.size.width * -0.1
//        let yPadding = mapRect.size.height * -0.1
//        
//        mapRect = mapRect.insetBy(dx: xPadding, dy: yPadding)
//        
//        options.mapRect = mapRect
//        options.scale = UIScreen.main.scale
//        options.size = CGSize(width: activityPreviewImageWidth, height: activityPreviewImageHeight)
//
//        let snapshotter = MKMapSnapshotter(options: options)
//        
//        do {
//            let imageSnapshot = try await snapshotter.start()
//            
//            if let inputImage = drawLineOnImage(imageSnapshot, options: options, coordinates: coordinates) {
//                return inputImage.pngData()
//            } else {
//                print("Failed to draw line on image, no image returned.")
//                return nil
//            }
//        } catch {
//            print("Failed to get image snapshot for drive: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    func drawLineOnImage(_ snapshot: MKMapSnapshotter.Snapshot, options: MKMapSnapshotter.Options, coordinates: [CLLocationCoordinate2D]) -> UIImage? {
//        
//        let image = snapshot.image
//        let size = options.size
//        let scale = options.traitCollection.displayScale
//        // for Retina
//        UIGraphicsBeginImageContextWithOptions(size, false, scale)
//        // draw image into ui graphics image context
//        image.draw(at: CGPoint.zero)
//        
//        // get the context for CoreGraphics
//        //let context = UIGraphicsGetCurrentContext()
//        
//        let path = UIBezierPath()
//        
//        let points = coordinates.map { snapshot.point(for: $0) }
//        
//        let smoothedCoordinates = interpolateCatmullRom(points: points, numberOfPointsPerSegment: 10)
//        
//        if let firstPoint = smoothedCoordinates.first {
//            path.move(to: firstPoint)
//        }
//        
//        for point in smoothedCoordinates {
//            path.addLine(to: point)
//        }
//        
//        UIColor.accent.setStroke()
//        
//        path.lineWidth = 5
//        path.stroke()
//        
//        let result  = UIGraphicsGetImageFromCurrentImageContext()
//        
//        UIGraphicsEndImageContext()
//        
//        return result != nil ? result : nil
//    }
//    
//    // Function to interpolate points using Catmull-Rom spline
//    func interpolateCatmullRom(points: [CGPoint], numberOfPointsPerSegment: Int) -> [CGPoint] {
//        var smoothPoints: [CGPoint] = []
//        
//        // Make sure we have at least 4 points to start with
//        guard points.count > 3 else { return points }
//        
//        for i in 1..<points.count - 2 {
//            let p0 = points[i - 1]
//            let p1 = points[i]
//            let p2 = points[i + 1]
//            let p3 = points[i + 2]
//            
//            for t in stride(from: 0.0, to: 1.0, by: 1.0 / CGFloat(numberOfPointsPerSegment)) {
//                let x = interpolateCatmullRom(p0.x, p1.x, p2.x, p3.x, t: t)
//                let y = interpolateCatmullRom(p0.y, p1.y, p2.y, p3.y, t: t)
//                smoothPoints.append(CGPoint(x: x, y: y))
//            }
//        }
//        
//        return smoothPoints
//    }
//
//    // Catmull-Rom spline interpolation for a single dimension (X or Y)
//    func interpolateCatmullRom(_ p0: CGFloat, _ p1: CGFloat, _ p2: CGFloat, _ p3: CGFloat, t: CGFloat) -> CGFloat {
//        let t2 = t * t
//        let t3 = t2 * t
//        
//        let v0 = (p2 - p0) * 0.5
//        let v1 = (p3 - p1) * 0.5
//        
//        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1
//    }
}

struct EditGasPriceView: View {
    @Binding var gasPrice: Double
    
    var formatter: Formatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("$")
                TextField(String(format: "%.2f", gasPrice), value: $gasPrice, formatter: formatter)
            }
                .padding()
            Divider()
            Spacer()
        }
        .navigationTitle("Fuel Price")
        .onDisappear {
            if gasPrice <= 0 {
                gasPrice = 3.50
            }
        }
    }
}

struct EditMPGView: View {
    @Binding var mpg: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TextField("\(mpg)", value: $mpg, formatter: NumberFormatter())
            }
            .padding()
            Divider()
            Spacer()
        }
        .navigationTitle("MPG")
        .onDisappear {
            if mpg <= 0 {
                mpg = 32
            }
        }
    }
}

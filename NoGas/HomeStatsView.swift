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
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var mostRecentDrive: Drive?
    @State private var selectedDrive: Drive?
    
    //@Query(sort: \Drive.startTime, order: .reverse) var drives: [Drive]
    
    @AppStorage("evCar") var evCar: Bool = true
    //@AppStorage("fuelCostBalance") var fuelCostBalance: Double = 0.00
    //@AppStorage("milesTraveled") var milesTraveled: Double = 0
    //@AppStorage("driveCount") var driveCount: Int = 0
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("mpg") var mpg: Int = 32
    
    //@State private var showAddTripView: Bool = false
    @State private var showRecordDrive: Bool = false
    
    @State var monthCards: [MonthCard] = []
    
//    var absFuelCostBalance: Double {
//        abs(fuelCostBalance)
//    }
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            Toggle("Electric Vehicle (EV)", isOn: $evCar)
                                .bold()
                                .tint(.accentColor)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(uiColor: .systemGray5))
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
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading) {
                                                    Text("$")
                                                        .font(.title)
                                                    + Text(String(format: "%.2f", gasPrice))
                                                        .font(.title.bold())
                                                    Text("Fuel price")
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "pencil")
                                            }
                                            .foregroundStyle(Color.primary)
                                            .padding(.horizontal)
                                            .frame(width: viewWidth/2 - 25, alignment: .leading)
                                            .padding(.vertical)
                                            .background {
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(Color(uiColor: UIColor.systemGray5))
                                            }
                                        }
                                        NavigationLink {
                                            EditMPGView(mpg: $mpg)
                                        } label: {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading) {
                                                    Text("\(mpg)")
                                                        .font(.title.bold())
                                                    Text("MPG")
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "pencil")
                                            }
                                            .foregroundStyle(Color.primary)
                                            .padding(.horizontal)
                                            .frame(width: viewWidth/2 - 25, alignment: .leading)
                                            .padding(.vertical)
                                            .background {
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(Color(uiColor: UIColor.systemGray5))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if let mostRecentDrive = self.mostRecentDrive {
                                Group {
                                    HStack {
                                        Text("Most recent drive")
                                            .font(.title3.bold())
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    DrivePreviewView(drive: mostRecentDrive, width: viewWidth, selectedDrive: $selectedDrive)
                                        .padding(.horizontal, 20)
                                }
                            }
                            
                            Group {
                                HStack {
                                    Text("History")
                                        .font(.title3.bold())
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 20) {
                                    ForEach(monthCards) { card in
                                        NavigationLink(value: card) {
                                            Text(card.name)
                                                .bold()
                                                .foregroundStyle(.white)
                                                .padding(.horizontal)
                                                .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55, alignment: .leading)
                                                .background {
                                                    RoundedRectangle(cornerRadius: 13)
                                                        .fill(Color(uiColor: .systemGray5))
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                            }
                        }
                        .padding(.vertical)
                    }
                    
                    ZStack(alignment: .top)  {
                        Button {
                            showRecordDrive = true
                        } label: {
                            Label("Record drive", systemImage: "steeringwheel")
                                .font(.title3.bold())
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: abs(viewWidth - 40), minHeight: 55, maxHeight: 55)
                                .background {
                                    RoundedRectangle(cornerRadius: 13)
                                        .fill(Color.accentColor)
                                }
                        }
                        .fullScreenCover(isPresented: $showRecordDrive) {
                            RecordDriveView(showRecordDriveView: $showRecordDrive)
                                .onDisappear {
                                    prepareSnapShotAndMonthsList()
                                }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, minHeight: 125, maxHeight: 125, alignment: .top)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .systemGray5))
                    }
                }
                .ignoresSafeArea(edges: [.bottom])
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
//                .onDisappear {
//                    self.mostRecentDrive = nil
//                }
            }
        }
    }
    
    func prepareSnapShotAndMonthsList() {
        let oldestDrives = DataService.getOldestDriveItems(modelContext: modelContext)
        let mostRecentDrives = DataService.getNewestDriveItems(modelContext: modelContext)
        if let mostRecentDrive = mostRecentDrives.first {
            self.mostRecentDrive = mostRecentDrive
        }
        
        if let firstDrive = oldestDrives.first {
            let firstDriveStartTime = firstDrive.startTime
            var testDate: Date = firstDriveStartTime.startDateOfMonth
            //if let backedUpDate = Calendar.current.date(byAdding: .month, value: -3, to: testDate) {
                
            var monthCards: [MonthCard] = []
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM yyyy"
        
            let dateForm2 = DateFormatter()
            dateForm2.dateFormat = "MM/dd/yyyy"
            
            while testDate <= Date() {
                print("test date: \(dateForm2.string(from: testDate))")
                
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
        mostRecentDrive = nil
    }
}

#Preview {
    HomeStatsView()
}

struct DrivePreviewView: View {
    let drive: Drive
    let width: CGFloat
    //let evCar: Bool
    
    @Binding var selectedDrive: Drive?
    
    @State private var snapshotImage: UIImage?
    
    var mapWidth: CGFloat {
        abs(width - 40)
    }
    
    var mapHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ZStack(alignment: .topLeading) {
                if let image = snapshotImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.white.opacity(0.001)
                        .onAppear {
                            generateSnapshot()
                        }
                }
            }
            .frame(width: mapWidth, height: mapHeight)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(alignment: .leading, spacing: 15) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("$")
                                .font(.title)
                                .foregroundStyle(drive.fuelValue > 0 ? Color.red:Color.green)
                            + Text(String(format: "%.2f", drive.absFuelValue))
                                .font(.title.bold())
                                .foregroundStyle(drive.fuelValue > 0 ? Color.red:Color.green)
                            Text("Fuel cost")
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(drive.miles, specifier: "%.2f")")
                                .font(.title.bold())
                            + Text("mi")
                                .font(.title3)
                            Text("Distance")
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                if drive.hrCount > 0 {
                                    Text("\(drive.hrCount)")
                                        .font(.title.bold())
                                    + Text("h")
                                        .font(.title3)
                                }
                                Text("\(drive.minCount)")
                                    .font(.title.bold())
                                + Text("m")
                                    .font(.title3)
                                Text("\(drive.secCount)")
                                    .font(.title.bold())
                                + Text("s")
                                    .font(.title3)
                            }
                            Text("Duration")
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(drive.milesPerHour, specifier: "%.2f")")
                                .font(.title.bold())
                            + Text("mph")
                                .font(.title3)
                            Text("Avg. Speed")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    Text(drive.startTimeStr)
                        .font(.headline)
                        .shadow(color: .black, radius: 5)
                    
                    Spacer()
                    
                    Button {
                        self.selectedDrive = drive
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background {
                                Circle()
                                    .fill(Color(uiColor: .systemGray4))
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 10)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: UIColor.systemGray5))
        }
        .onChange(of: drive) {
            print("most recent drive changed")
            generateSnapshot()
        }
    }
    
    func generateSnapshot() {
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
        options.scale = UIScreen.main.scale
        options.size = CGSize(width: mapWidth, height: mapHeight) // Adjust size as needed

        let snapshotter = MKMapSnapshotter(options: options)
        
        
        snapshotter.start { snapshot, error in
            
            guard let snapshot = snapshot else {
                return
            }
            
            let inputImage = drawLineOnImage(snapshot, options: options, coordinates: coordinates)
            
            snapshotImage = inputImage
            
//            if let snapshot = snapshot {
//
//                // Create an image context to draw the polyline
//                UIGraphicsBeginImageContextWithOptions(options.size, false, options.scale)
//                snapshot.image.draw(at: .zero)
//
//                // Draw the polyline on the snapshot
//                let context = UIGraphicsGetCurrentContext()
//                context?.setStrokeColor(UIColor.accent.cgColor)
//                context?.setLineWidth(5)
//
//                let points = polyline.points()
//                let path = UIBezierPath()
//
//                for i in 0..<polyline.pointCount - 1 {
//                    let coordinate = points[i].coordinate
//                    let point = snapshot.point(for: coordinate)
//
//                    if i == 0 {
//                        path.move(to: point)
//                    } else {
//                        path.addLine(to: point)
//                    }
//                }
//
//                context?.addPath(path.cgPath)
//                context?.strokePath()
//
//                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
//                UIGraphicsEndImageContext()
//
//                snapshotImage = finalImage
//            }
        }
    }
    
    func drawLineOnImage(_ snapshot: MKMapSnapshotter.Snapshot, options: MKMapSnapshotter.Options, coordinates: [CLLocationCoordinate2D]) -> UIImage? {
        let image = snapshot.image
        let size = options.size
        // for Retina
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        
        // draw image into ui graphics image context
        image.draw(at: CGPoint.zero)
        
        // get the context for CoreGraphics
        let context = UIGraphicsGetCurrentContext()
        
        if let context = context, let firstCoordinate = coordinates.first {
            // set stroking width and color of the context
            context.setLineWidth(5.0)
            context.setStrokeColor(UIColor.accent.cgColor)
            // move to start to begin drawing line
            context.move(to: snapshot.point(for: firstCoordinate))
            
            for i in 0...coordinates.count - 1 {
                context.addLine(to: snapshot.point(for: coordinates[i]))
                context.move(to: snapshot.point(for: coordinates[i]))
            }
            
            context.strokePath()
        }
        
        let result  = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result != nil ? result : nil
    }
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

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
    
    @EnvironmentObject private var driveManager: DriveManager
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("metricSystem") var metricSystem: Bool = false
    @AppStorage("evCar") var evCar: Bool = true
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("metricFuelPrice") var metricFuelPrice: Double = 7.00
    @AppStorage("mpg") var mpg: Int = 32
    @AppStorage("kmpl") var kmpl: Int = 42
    
    @State private var selectedDrive: Drive?
    @State private var showRecordDrive: Bool = false
    @State var monthCards: [MonthCard] = []
    @State private var showMostRecentTripReviewView = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            
            NavigationStack {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            if let drive = self.driveManager.mostRecentDrive {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Most recent drive")
                                            .font(.title3.bold())
                                        Spacer()
                                    }
                                    
                                    DrivePreviewView(metricSystem: metricSystem, drive: drive, width: viewWidth, selectedDrive: $selectedDrive)
                                        .onTapGesture {
                                            self.showMostRecentTripReviewView = true
                                        }
                                        .navigationDestination(isPresented: $showMostRecentTripReviewView) {
                                            if let drive = self.driveManager.mostRecentDrive {
                                                ReviewDriveView(drive: drive)
                                            }
                                        }
                                }
                            }
                            
                            
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Drive history")
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
                                                        .fill(Color(uiColor: .systemGray6))
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button {
                            showRecordDrive = true
                        } label: {
                            Text("New drive")
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
                        .padding(.vertical)
                    }
                }
                .navigationDestination(for: MonthCard.self) { card in
                    MonthDriveHistoryView(metricSystem: metricSystem, card: card)
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .fullScreenCover(isPresented: $showSettings) {
                            DriveSettingsView()
                        }
                    }
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
    let metricSystem: Bool
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
                            .scaledToFit()
                    } else {
                        Color.white.opacity(0.001)
                            .scaledToFill()
                            .frame(height: 200)
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
                
                
                // Drive stats
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("$")
                                .font(.title2)
                                .foregroundStyle(drive.fuelValue < 0 ? Color.red:Color.blue)
                            + Text(String(format: "%.2f", drive.fuelValue))
                                .font(.title2.bold())
                                .foregroundStyle(drive.fuelValue < 0 ? Color.red:Color.blue)
                            Text("Fuel cost")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if metricSystem {
                                Text("\(drive.kilometers, specifier: "%.1f")")
                                    .font(.title2.bold())
                                + Text("km")
                                    .font(.title3)
                            } else {
                                Text("\(drive.miles, specifier: "%.1f")")
                                    .font(.title2.bold())
                                + Text("mi")
                                    .font(.title3)
                            }
                            Text("Distance")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 5) {
                                if drive.hrCount > 0 {
                                    Text("\(drive.hrCount)")
                                        .font(.title2.bold())
                                    + Text("hr")
                                        .font(.title3)
                                }
                                Text("\(drive.minCount)")
                                    .font(.title2.bold())
                                + Text("min")
                                    .font(.title3)
//                                Text("\(drive.secCount)")
//                                    .font(.title2.bold())
//                                + Text("s")
//                                    .font(.title3)
                            }
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if metricSystem {
                                Text("\(drive.kilometersPerHour, specifier: "%.0f")")
                                    .font(.title2.bold())
                                + Text("kmph")
                                    .font(.title3)
                            } else {
                                Text("\(drive.milesPerHour, specifier: "%.0f")")
                                    .font(.title2.bold())
                                + Text("mph")
                                    .font(.title3)
                            }
                            Text("Avg. speed")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    
                        VStack(alignment: .leading, spacing: 0) {
                            if metricSystem {
                                Text(String(format: "%.0f", drive.elevation))
                                    .font(.title2.bold())
                                + Text("m")
                                    .font(.title3)
                            } else {
                                Text(String(format: "%.0f", drive.elevationClimbedInFeet))
                                    .font(.title2.bold())
                                + Text("ft")
                                    .font(.title3)
                            }
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
                    .fill(Color(uiColor: UIColor.systemGray6))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Drive start time
            HStack {
                if metricSystem {
                    Text(drive.startTime24hrStr)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.gray)
                } else {
                    Text(drive.startTimeStr)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.gray)
                    //.shadow(color: .black, radius: 5)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            //if drive.tripPreviewImageData == nil {
                let size = CGSize(width: mapWidth, height: mapHeight)
                let coordinates = drive.orderedLocations.map {
                    return CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }
                let generator = MapSnapshotGenerator()
                generator.generateSnapshot(from: coordinates, size: size) { data in
                    drive.tripPreviewImageData = data
                }
            //}
        }
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

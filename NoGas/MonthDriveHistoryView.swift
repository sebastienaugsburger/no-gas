//
//  MonthDriveHistoryView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/31/25.
//

import SwiftUI
import SwiftData

struct MonthDriveHistoryView: View {
    
    @Environment(\.modelContext) private var context
    
    let card: MonthCard
    
    @State var selectedDrive: Drive?
    @State private var drives: [Drive] = []
    @State private var secondsTotal = 0
    @State private var totalTimeString = ""
    
    var distance: Double {
        drives.map { $0.miles }.reduce(0, +)
    }
    
    var totalFuelCost: Double {
        drives.map { $0.fuelValue }.reduce(0, +)
    }
    
    var totalElevationInFeet: Double {
        drives.map { $0.elevationClimbedInFeet }.reduce(0, +)
    }
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Stats")
                                .font(.title3.bold())
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("$")
                                    .font(.title)
                                    .foregroundStyle(totalFuelCost > 0 ? Color.red:Color.green)
                                + Text(String(format: "%.2f", abs(totalFuelCost)))
                                    .font(.title.bold())
                                    .foregroundStyle(totalFuelCost > 0 ? Color.red:Color.green)
                                Text("Fuel cost")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray5))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(distance, specifier: "%.2f")")
                                    .font(.title.bold())
                                + Text("mi")
                                    .font(.title3)
                                Text("Distance")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray5))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(totalTimeString)
                                    .font(.title.bold())
                                Text("Time")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray5))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(String(format: "%.0f", totalElevationInFeet))
                                    .font(.title.bold())
                                + Text("ft")
                                    .font(.title3)
                                Text("Elevation")
                                    .foregroundStyle(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray5))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Trips (\(drives.count))")
                                .font(.title3.bold())
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 25) {
                            // List out drives
                            ForEach(drives) { drive in
                                NavigationLink(value: drive) {
                                    DrivePreviewView(drive: drive, width: viewWidth, selectedDrive: $selectedDrive)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .navigationDestination(for: Drive.self) { drive in
                            ReviewDriveView(drive: drive)
                        }
                    }
                }
                .padding(.vertical)
                .alert(item: $selectedDrive) { drive in
                    Alert(
                        title: Text("Delete drive"),
                        message: Text("Are you sure you want to delete your drive from \(drive.startTime.formatted())?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteDrive(in: context, drive: drive)
                        },
                        secondaryButton: .cancel()
                    )
                }
                .onAppear {
                    drives = DataService.fetchDrivesInMonth(in: context, for: card.date)
                    print("Elevations: \(drives.map { $0.elevation })")
                    
                    secondsTotal = getTotalSeconds(from: drives)
                    let numberOfHours = secondsTotal / 3600
                    var numberOfMinutes = secondsTotal / 60
                    if numberOfHours > 0 {
                        let secondsRemainder = secondsTotal - (numberOfHours * 3600)
                        numberOfMinutes = secondsRemainder / 60
                        totalTimeString = "\(numberOfHours)h \(numberOfMinutes)m"
                    } else {
                        totalTimeString = "\(numberOfMinutes)s"
                    }
                }
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func deleteDrive(in context: ModelContext, drive: Drive) {
        context.delete(drive)
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        drives = drives.filter { $0.id != drive.id }
    }
    
    func getTotalSeconds(from drives: [Drive]) -> Int {
        var secondsTotal = 0
        
        for drive in drives.reversed() {
            guard let endTime = drive.endTime else { continue }
            let interval = endTime - drive.startTime
            if let seconds = interval.second {
                secondsTotal += seconds
            }
        }
        
        return secondsTotal
    }
    
    func getTotalElevation(from drives: [Drive]) -> Double {
        var totalElevation = 0.0
        return totalElevation
    }
}

#Preview {
    MonthDriveHistoryView(card: MonthCard(name: "March 2025", date: .now))
}

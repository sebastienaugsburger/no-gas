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
    
    var distance: Double {
        let distances = drives.map { $0.miles }
        return distances.reduce(0, +)
    }
    
    var totalFuelCost: Double {
        let costs = drives.map { $0.fuelValue }
        return costs.reduce(0, +)
    }
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("$")
                                .font(.title)
                                .foregroundStyle(totalFuelCost > 0 ? Color.red:Color.green)
                            + Text(String(format: "%.2f", abs(totalFuelCost)))
                                .font(.title.bold())
                                .foregroundStyle(totalFuelCost > 0 ? Color.red:Color.green)
                            Text("Month fuel cost")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(uiColor: .systemGray5))
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(distance, specifier: "%.2f")")
                                .font(.title.bold())
                            + Text("mi")
                                .font(.title3)
                            Text("Month distance")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(uiColor: .systemGray5))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    HStack {
                        Text("Drives \(drives.count)")
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
}

#Preview {
    MonthDriveHistoryView(card: MonthCard(name: "March 2025", date: .now))
}

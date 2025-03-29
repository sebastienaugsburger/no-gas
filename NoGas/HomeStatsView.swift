//
//  HomeStatsView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/25/25.
//

import SwiftUI
import SwiftData

struct HomeStatsView: View {
    
    @AppStorage("moneySaved") var moneySaved: Double = 0.00
    @AppStorage("milesTraveled") var milesTraveled: Int = 0
    @AppStorage("tripCount") var tripCount: Int = 0
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("mpg") var mpg: Int = 32
    
    @Query(sort: \Drive.startTime, order: .reverse) private var drives: [Drive]
    
    @State private var showAddTripView: Bool = false
    @State private var showRecordDrive: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width
            NavigationStack {
                
                ScrollView {
                    VStack(spacing: 20) {
                        Button {
                            showRecordDrive = true
                        } label: {
                            Label("Record Drive", systemImage: "steeringwheel")
                                .font(.title3.bold())
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: viewWidth - 40, minHeight: 55, maxHeight: 55)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(uiColor: UIColor.systemGray5))
                                }
                        }
                        .fullScreenCover(isPresented: $showRecordDrive) {
                            RecordDriveView(showRecordDriveView: $showRecordDrive)
                        }
                        
                        Button {
                            showAddTripView = true
                        } label: {
                            Label("Add Trip", systemImage: "plus")
                                .font(.title3.bold())
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: viewWidth - 40, minHeight: 55, maxHeight: 55)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(uiColor: UIColor.systemGray5))
                                }
                        }
                        .fullScreenCover(isPresented: $showAddTripView) {
                            AddTripView(showAddTrip: $showAddTripView)
                        }
                        
                        Group {
//                            HStack {
//                                Text("Stats")
//                                    .font(.title3.bold())
//                                Spacer()
//                            }
//                            .padding(.horizontal, 20)
                            
                            HStack(spacing: 10) {
                                VStack(alignment: .leading) {
                                    Text(String(format: "$%.2f", moneySaved))
                                        .font(.title.bold())
                                    Text("Money saved")
                                }
                                .padding(.horizontal)
                                .frame(width: viewWidth/2 - 25, alignment: .leading)
                                .padding(.vertical)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(uiColor: UIColor.systemGray5))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("\(milesTraveled)")
                                        .font(.title.bold())
                                    Text("Miles")
                                }
                                .padding(.horizontal)
                                .frame(width: viewWidth/2 - 25, alignment: .leading)
                                .padding(.vertical)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(uiColor: UIColor.systemGray5))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Group {
//                            HStack {
//                                Text("Gas Price & MPG")
//                                    .font(.title3.bold())
//                                Spacer()
//                            }
//                            .padding(.horizontal, 20)
                            
                            HStack(spacing: 10) {
                                NavigationLink {
                                    EditGasPriceView(gasPrice: $gasPrice)
                                } label: {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            Text(String(format: "$%.2f", gasPrice))
                                                .font(.title.bold())
                                            Text("Gas price")
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
                        
                        Group {
                            HStack {
                                Text("Drives \(drives.count)")
                                    .font(.title3.bold())
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                // List out drives
                                ForEach(drives) { drive in
                                    VStack(alignment: .leading) {
                                        Text("Drive on: \(drive.startTime.formatted())")
                                            .font(.headline)
                                        Text("Distance: \(drive.distance, specifier: "%.2f") meters")
                                            .font(.subheadline)
                                        if let firstLocation = drive.locations.first {
                                            Text("Start Location: \(firstLocation.latitude), \(firstLocation.longitude)")
                                                .font(.caption)
                                        }
                                        if let endLocation = drive.locations.last {
                                            Text("End Location: \(endLocation.latitude), \(endLocation.longitude)")
                                                .font(.caption)
                                        }
                                        Text("Location Count: \(drive.locations.count)")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.trailing, 20)
                                    
                                    if drive.id != drives.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
                .padding(.vertical)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        
                    }
                }
            }
        }
    }
}

#Preview {
    HomeStatsView()
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
        .navigationTitle("Gas Price")
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
    }
}

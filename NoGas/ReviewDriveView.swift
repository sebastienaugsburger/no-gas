//
//  ReviewDriveView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/30/25.
//

import SwiftUI
import Charts

struct ReviewDriveView: View {
    
    @AppStorage("metricSystem") var metricSystem: Bool = false
    
    let drive: Drive
    let statBlockHeight: CGFloat = 130
    
    var mphSpeedData: [(time: Int, speed: Double)] {
        //let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "h:mm a"
        var index = 0
        var speedData = [(time: Int, speed: Double)]()
        for loc in drive.orderedLocations {
            if index % 4 == 0 {
                let speed = (loc.speedMetersPerSecond / 1609.34) * 3600
                print("Speed: \(speed)")
                let count = speedData.count
                //let dateString = dateFormatter.string(from: loc.createdAt)
                speedData.append((time: count, speed: speed))
            }
            index += 1
        }
        return speedData
    }
    
    var kmphSpeedData: [(time: Int, speed: Double)] {
        //let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "h:mm a"
        var index = 0
        var speedData = [(time: Int, speed: Double)]()
        for loc in drive.orderedLocations {
            if index % 4 == 0 {
                let speed = (loc.speedMetersPerSecond / 1000) * 3600
                print("Speed: \(speed)")
                let count = speedData.count
                //let dateString = dateFormatter.string(from: loc.createdAt)
                speedData.append((time: count, speed: speed))
            }
            index += 1
        }
        return speedData
    }
    
    var maxMphSpeed: Double {
        mphSpeedData.map(\.speed).max() ?? 99.0
    }
    
    var minMphSpeed: Double {
        mphSpeedData.map(\.speed).min() ?? 0.0
    }
    
    var maxKmphSpeed: Double {
        kmphSpeedData.map(\.speed).max() ?? 99.0
    }
    
    var minKmphSpeed: Double {
        kmphSpeedData.map(\.speed).min() ?? 0.0
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    if let imageData = drive.tripPreviewImageData {
                        if let image = UIImage(data: imageData) {
                            NavigationLink {
                                ReviewDriveMapViewRepresentable(driveLocations: drive.orderedLocations)
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: abs(geo.size.width - 40), height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    let statBlockWidth = (geo.size.width/2 - 25)
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("$")
                                    .font(.title)
                                    .foregroundStyle(drive.fuelValue < 0 ? Color.red:Color.blue)
                                + Text(String(format: "%.2f", drive.fuelValue))
                                    .font(.title.bold())
                                    .foregroundStyle(drive.fuelValue < 0 ? Color.red:Color.blue)
                                Text("Fuel cost")
                                //.font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                            .scaledToFit()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                if metricSystem {
                                    Text("\(drive.kilometers, specifier: drive.kilometers >= 10 ? "%.0f":"%.1f")")
                                        .font(.title.bold())
                                    + Text("km")
                                        .font(.title3)
                                } else {
                                    Text("\(drive.miles, specifier: drive.miles >= 10 ? "%.0f":"%.1f")")
                                        .font(.title.bold())
                                    + Text("mi")
                                        .font(.title3)
                                }
                                Text("Distance")
                                //.font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                            .scaledToFit()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                            }
                        }
                        
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 5) {
                                    if drive.hrCount > 0 {
                                        Text("\(drive.hrCount)")
                                            .font(.title.bold())
                                        + Text("hr")
                                            .font(.title3)
                                    }
                                    Text("\(drive.minCount)")
                                        .font(.title.bold())
                                    + Text("min")
                                        .font(.title3)
                                    
                                    //                            Text("\(drive.secCount)")
                                    //                                .font(.title.bold())
                                    //                            + Text("s")
                                    //                                .font(.title3)
                                }
                                
                                Text("Duration")
                                //.font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                            .scaledToFit()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                if metricSystem {
                                    Text("\(drive.kilometersPerHour, specifier: "%.0f")")
                                        .font(.title.bold())
                                    + Text("kmph")
                                        .font(.title3)
                                } else {
                                    Text("\(drive.milesPerHour, specifier: "%.0f")")
                                        .font(.title.bold())
                                    + Text("mph")
                                        .font(.title3)
                                }
                                Text("Avg. speed")
                                //.font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                            .scaledToFit()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                            }
                        }
                        
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                if metricSystem {
                                    Text(String(format: "%.0f", drive.elevation))
                                        .font(.title.bold())
                                    + Text("m")
                                        .font(.title3)
                                } else {
                                    Text(String(format: "%.0f", drive.elevationClimbedInFeet))
                                        .font(.title.bold())
                                    + Text("ft")
                                        .font(.title3)
                                }
                                Text("Elevation")
                                //.font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                            .scaledToFit()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .systemGray6))
                            }
                            
                            Text("")
                                .frame(minWidth: statBlockWidth, minHeight: statBlockHeight)
                                .scaledToFit()
                                .background {
                                    Rectangle()
                                        .fill(.white.opacity(0.001))
                                }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Drive Speed")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        
                        if metricSystem {
                            // Bar chart
                            Chart {
                                ForEach(kmphSpeedData, id: \.time) { data in
                                    AreaMark(
                                        x: .value("Time", data.time),
                                        y: .value("Speed", data.speed)
                                    )
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.accent.opacity(1.0),
                                            Color.accent.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                }
                            }
                            //.chartXScale(domain: speedData.map(\.time).min...speedData.map(\.time).max)
                            .chartYScale(domain: 0...(maxKmphSpeed + 5))
                            .chartYAxisLabel("Speed (kmph)")
                            .chartXAxis(.hidden)
                            .frame(height: 300)
                        } else {
                            // Bar chart
                            Chart {
                                ForEach(mphSpeedData, id: \.time) { data in
                                    AreaMark(
                                        x: .value("Time", data.time),
                                        y: .value("Speed", data.speed)
                                    )
                                    .foregroundStyle(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.accent.opacity(1.0),
                                            Color.accent.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                }
                            }
                            //.chartXScale(domain: speedData.map(\.time).min...speedData.map(\.time).max)
                            .chartYScale(domain: 0...(maxMphSpeed + 5))
                            .chartYAxisLabel("Speed (mph)")
                            .chartXAxis(.hidden)
                            .frame(height: 300)
                        }
                    }
                    
                    .padding(.top)
                    .padding(.bottom)
                }
                .padding(.horizontal, 20)
                .padding(.vertical)
            }
            .navigationTitle("\(drive.startTimeStr)")
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    ReviewDriveView(drive: Drive(startTime: .now))
}

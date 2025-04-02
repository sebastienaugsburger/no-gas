//
//  ReviewDriveView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/30/25.
//

import SwiftUI

struct ReviewDriveView: View {
    
    let drive: Drive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ReviewDriveMapViewRepresentable(driveLocations: drive.orderedLocations)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
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
                .padding(.bottom)
            }
        }
        .navigationTitle("Drive: \(drive.startTimeStr)")
    }
}

#Preview {
    ReviewDriveView(drive: Drive(startTime: .now))
}

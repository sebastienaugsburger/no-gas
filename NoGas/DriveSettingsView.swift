//
//  DriveSettingsView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 4/20/25.
//

import SwiftUI

struct DriveSettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("metricSystem") var metricSystem: Bool = false
    @AppStorage("evCar") var evCar: Bool = true
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("metricFuelPrice") var metricFuelPrice: Double = 7.00
    @AppStorage("mpg") var mpg: Int = 32
    @AppStorage("kmpl") var kmpl: Int = 42
    
    var body: some View {
        GeometryReader { geo in
            
            let viewWidth = geo.size.width
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(metricSystem ? "Petrol info":"Gas info")
                            .font(.title3.bold())
                        
                        HStack(spacing: 10) {
                            if metricSystem {
                                NavigationLink {
                                    EditPetrolPriceView(price: $metricFuelPrice)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("$")
                                                .font(.title)
                                            + Text(String(format: "%.2f", metricFuelPrice))
                                                .font(.title.bold())
                                            Text("Petrol price ($/l).")
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
                                            .fill(Color(uiColor: UIColor.systemGray6))
                                    }
                                }
                                
                                NavigationLink {
                                    EditKMPGView(value: $kmpl)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(kmpl)")
                                                .font(.title.bold())
                                            Text("KMPL")
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
                                            .fill(Color(uiColor: UIColor.systemGray6))
                                    }
                                }
                            } else {
                                NavigationLink {
                                    EditGasPriceView(gasPrice: $gasPrice)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("$")
                                                .font(.title)
                                            + Text(String(format: "%.2f", gasPrice))
                                                .font(.title.bold())
                                            Text("Gas price ($/gal)")
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
                                            .fill(Color(uiColor: UIColor.systemGray6))
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
                                            .fill(Color(uiColor: UIColor.systemGray6))
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vehicle type")
                            .font(.title3.bold())
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width/2 - 20, height: 60)
                                .offset(x: evCar ? 0:geo.size.width/2 - 10)
                                .animation(.easeIn, value: evCar)
                            HStack {
                                Text("Electric")
                                    .bold()
                                    .frame(width: geo.size.width/2 - 20, height: 60)
                                    .background(Color.white.opacity(0.001))
                                    .foregroundStyle(evCar ? .black:.white)
                                    .onTapGesture {
                                        evCar = true
                                    }
                                Text("Combustion")
                                    .bold()
                                    .frame(width: geo.size.width/2 - 20, height: 60)
                                    .background(Color.white.opacity(0.001))
                                    .foregroundStyle(evCar == false ? .black:.white)
                                    .onTapGesture {
                                        evCar = false
                                    }
                            }
                        }
                        .background {
                            Capsule()
                                .fill(Color(uiColor: .systemGray6))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Unit of measurement")
                            .font(.title3.bold())
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width/2 - 20, height: 60)
                                .offset(x: metricSystem ? 0:geo.size.width/2 - 10)
                                .animation(.easeIn, value: metricSystem)
                            HStack {
                                Text("Metric")
                                    .bold()
                                    .frame(width: geo.size.width/2 - 20, height: 60)
                                    .background(Color.white.opacity(0.001))
                                    .foregroundStyle(metricSystem ? .black:.white)
                                    .onTapGesture {
                                        metricSystem = true
                                    }
                                Text("Imperial")
                                    .bold()
                                    .frame(width: geo.size.width/2 - 20, height: 60)
                                    .background(Color.white.opacity(0.001))
                                    .foregroundStyle(metricSystem == false ? .black:.white)
                                    .onTapGesture {
                                        metricSystem = false
                                    }
                            }
                        }
                        .background {
                            Capsule()
                                .fill(Color(uiColor: .systemGray6))
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("Drive settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DriveSettingsView()
}

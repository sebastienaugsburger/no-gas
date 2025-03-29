//
//  AddTripView.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/25/25.
//

import SwiftUI

struct AddTripView: View {
    
    @AppStorage("moneySaved") var moneySaved: Double = 0.00
    @AppStorage("milesTraveled") var milesTraveled: Int = 0
    @AppStorage("tripCount") var tripCount: Int = 0
    @AppStorage("gasPrice") var gasPrice: Double = 4.07
    @AppStorage("mpg") var mpg: Int = 32
    
    @Binding var showAddTrip: Bool
    
    @State private var miles: Int = 0
    
    var moneyFormatter: Formatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var newMoneySaved: Double {
        (Double(miles)/Double(mpg)) * gasPrice
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Form {
                    Section{
                        TextField("\(miles)", value: $miles, formatter: NumberFormatter())
                    } header: {
                        Text("Miles")
                    }
                    
                    Section{
                        HStack(spacing: 0) {
                            Text("$")
                            TextField("\(gasPrice)", value: $gasPrice, formatter: moneyFormatter)
                        }
                    } header: {
                        Text("Gas Price")
                    }
                    
                    Section{
                        TextField("\(mpg)", value: $mpg, formatter: NumberFormatter())
                    } header: {
                        Text("MPG")
                    }
                    
                    
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "$%.2f", newMoneySaved))
                            .font(.title3.bold())
                        Text("Money saved")
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Button {
                    
                } label: {
                    Text("Add")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.accentColor)
                        }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddTrip = false
                    }
                }
            }
        }
        
    }
}

#Preview {
    AddTripView(showAddTrip: .constant(true))
}

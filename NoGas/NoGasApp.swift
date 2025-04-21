//
//  NoGasApp.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 3/25/25.
//

import SwiftUI
import SwiftData

@main
struct NoGasApp: App {
    
    @StateObject private var driveManager = DriveManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Drive.self])
        let container = try! ModelContainer(for: schema)
        return container
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environmentObject(driveManager)
                //.preferredColorScheme(.dark)
        }
    }
}

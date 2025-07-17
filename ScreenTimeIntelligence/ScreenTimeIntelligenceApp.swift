//
//  ScreenTimeIntelligenceApp.swift
//  ScreenTimeIntelligence
//
//  Created by Pallav Agarwal on 7/16/25.
//

import SwiftUI
import FamilyControls

@main
struct ScreenTimeIntelligenceApp: App {
    @StateObject private var authManager = AuthorizationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .task {
                    await authManager.requestAuthorization()
                }
        }
    }
}

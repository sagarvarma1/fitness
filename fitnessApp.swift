//
//  fitnessApp.swift
//  fitness
//
//  Created by Sagar Varma on 4/7/25.
//

import SwiftUI

@main
struct fitnessApp: App {
    // State to track which view to show
    @State private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            // Check if user has completed onboarding before
            Group {
                if hasCompletedOnboarding {
                    HomePage()
                } else {
                    WelcomeView()
                }
            }
            .onAppear {
                // Check UserDefaults for initialization status when app starts
                let defaults = UserDefaults.standard
                hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedInitialSetup")
            }
        }
    }
}

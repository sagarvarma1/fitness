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
    @State private var showWorkoutCompletedView: Bool = false
    @StateObject private var notificationCenter = NotificationHandler()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
                
                // Conditionally show workout completed view as an overlay
                if showWorkoutCompletedView {
                    WorkoutCompletedView()
                        .transition(.move(edge: .bottom))
                        .zIndex(100) // Keep on top
                }
            }
            .onChange(of: notificationCenter.showWorkoutCompletedView) { show in
                if show {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showWorkoutCompletedView = true
                    }
                    notificationCenter.showWorkoutCompletedView = false
                }
            }
            .onChange(of: notificationCenter.hideWorkoutCompletedView) { hide in
                if hide {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showWorkoutCompletedView = false
                    }
                    notificationCenter.hideWorkoutCompletedView = false
                }
            }
            // Direct notification handlers for extra reliability
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowWorkoutCompletedView"))) { _ in
                print("App received ShowWorkoutCompletedView notification")
                withAnimation(.easeIn(duration: 0.3)) {
                    showWorkoutCompletedView = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HideWorkoutCompletedView"))) { _ in
                print("App received HideWorkoutCompletedView notification")
                withAnimation(.easeOut(duration: 0.3)) {
                    showWorkoutCompletedView = false
                }
            }
        }
    }
}

// Notification handler class to observe notifications
class NotificationHandler: ObservableObject {
    @Published var showWorkoutCompletedView: Bool = false
    @Published var hideWorkoutCompletedView: Bool = false
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowWorkoutCompletedView"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showWorkoutCompletedView = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HideWorkoutCompletedView"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hideWorkoutCompletedView = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

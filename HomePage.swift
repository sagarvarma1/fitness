import SwiftUI
import UIKit

struct HomePage: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var navigateToWorkout = false
    @State private var showingError = false
    @State private var refreshID = UUID() // Add refresh ID to force view refresh
    
    var body: some View {
            ZStack {
                // Same gradient background as WelcomeView for consistency
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                // Top logo only - removed navigation area with reset button
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    .padding(.top, 10)
                    
                    if let week = viewModel.currentWeek, let day = viewModel.currentDay {
                        // Week Title
                        Text(week.name)
                        .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Day name
                        Text(day.name)
                        .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 5)
                        
                    // Using a custom fullScreenCover instead of NavigationLink
                        Button("GET STARTED") {
                            self.navigateToWorkout = true
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(15)
                        .padding(.horizontal, 30)
                    .fullScreenCover(isPresented: $navigateToWorkout) {
                        // Custom workout view without navigation elements
                        WorkoutProgressView(viewModel: viewModel, isPresented: $navigateToWorkout)
                    }
                        
                        // Workout Details
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                // Focus description
                                Text("Focus: \(day.focus)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 5)
                                
                                // Workout description
                                Text(day.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.bottom, 10)
                                
                                // Exercise list
                                Text("Today's Exercises:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(day.exercises) { exercise in
                                    HStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(exercise.title)
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.callout)
                                        
                                        Spacer()
                                    }
                                    .padding(.leading, 5)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }
                    } else {
                        // Fallback if data can't be loaded
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .padding()
                            
                            Text("Could not load workout data")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button(action: {
                                viewModel.loadWorkoutData()
                            }) {
                                Text("Reload")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 30)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    }
                    
                    Spacer()
                }
            .padding(.top, 5) // Reduced top padding to use more space
            }
            .id(refreshID) // Force refresh when ID changes
            .onAppear {
                print("HomePage appeared")
                // Ensure we've completed initialization by setting the flag
                UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
                
                // Reload state from UserDefaults
                viewModel.reloadSavedState()
                
                // Load workout data when view appears
                if viewModel.workoutProgram == nil {
                    viewModel.loadWorkoutData()
                }
                
                // Setup notification observer
                setupRefreshObserver()
            }
            .onDisappear {
                // Remove notification observer
                NotificationCenter.default.removeObserver(self)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHomeView"))) { _ in
                print("Received RefreshHomeView notification")
                // Force view refresh
                self.refreshID = UUID()
                
                // Reload data
                viewModel.reloadSavedState()
                viewModel.loadWorkoutData()
            }
        }
    
    // Setup notification observer - keeping for backward compatibility
    private func setupRefreshObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshHomeView"),
            object: nil,
            queue: .main
        ) { _ in
            print("Observer caught RefreshHomeView notification")
            // Reload state from UserDefaults
            viewModel.reloadSavedState()
            
            // Reload workout data
            viewModel.loadWorkoutData()
            
            // Force view refresh
            self.refreshID = UUID()
        }
    }
}

// Custom workout progress view without any navigation elements
struct WorkoutProgressView: View {
    var viewModel: WorkoutViewModel
    @Binding var isPresented: Bool
    
    // Timer state
    @State private var isTimerRunning = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    @State private var workoutWasStarted = false // Track if workout was previously started
    
    // Exercise states
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise? = nil
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 15) {
                // Close button
                HStack {
                    Button(action: {
                        stopTimer() // Stop timer before dismissing
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Add fire logo
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if let week = viewModel.currentWeek, let day = viewModel.currentDay {
                    // Combined Week and Day on single line
                    Text("\(week.name) - \(day.name)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    // Timer section - moved up
                    VStack(spacing: 10) { // Reduced spacing
                        // Timer display
                        Text(formatTime(seconds: elapsedSeconds))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.vertical, 5) // Reduced vertical padding
                        
                        // Single toggle button for timer
                        Button(action: isTimerRunning ? stopTimer : startTimer) {
                            HStack {
                                Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                                Text(isTimerRunning ? "Stop Workout" : (workoutWasStarted ? "Continue Workout" : "Start Workout"))
                            }
                            .padding(.vertical, 10) // Reduced padding
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .background(isTimerRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10) // Reduced padding
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Exercises list
                    ScrollView {
                        VStack(spacing: 10) { // Reduced spacing between exercises
                            Text("Today's Exercises")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 2) // Minimal top padding
                            
                            ForEach(Array(day.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseTile(
                                    exercise: exercise,
                                    onMore: {
                                        selectedExercise = exercise
                                        showingExerciseDetail = true
                                    },
                                    onComplete: {
                                        viewModel.toggleExerciseCompletion(exerciseIndex: index)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Complete workout button - reduced bottom padding
                    Button("COMPLETE WORKOUT") {
                        stopTimer()
                        viewModel.advanceToNextDay()
                        
                        // Use a flag for navigation instead of direct presentation
                        isPresented = false
                        
                        // Add slight delay before showing completion view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Use NotificationCenter to present the completion view from the root level
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowWorkoutCompletedView"),
                                object: nil
                            )
                        }
                    }
                    .padding(.vertical, 12) // Slightly reduced padding
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .font(.headline)
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20) // Reduced bottom padding
                }
            }
            
            // Custom modal overlay instead of sheet
            if showingExerciseDetail, let exercise = selectedExercise {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingExerciseDetail = false
                    }
                
                VStack {
                    Spacer()
                    
                    // Exercise detail card
                    VStack(spacing: 15) {
                        // Exercise title
                        Text(exercise.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                        
                        // Workout stats cards
                        HStack(spacing: 12) {
                            if let sets = exercise.sets {
                                StatCard(label: "Sets", value: "\(sets)")
                            }
                            
                            if let reps = exercise.reps {
                                StatCard(label: "Reps", value: "\(reps)")
                            }
                            
                            if let duration = exercise.duration {
                                StatCard(label: "Duration", value: duration)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Description
                        if let description = exercise.description {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("How to perform")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 2)
                                    
                                    Text(description)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(5)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        // Done button
                        Button(action: {
                            showingExerciseDetail = false
                        }) {
                            Text("Close")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                    }
                    .padding(.vertical)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onDisappear {
            // Cleanup timer when view disappears
            stopTimer()
        }
    }
    
    // Timer functions
    private func startTimer() {
        isTimerRunning = true
        workoutWasStarted = true // Set the flag that workout has been started
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        // Note: We don't reset workoutWasStarted here, so we can show "Continue Workout"
    }
    
    private func resetTimer() {
        stopTimer()
        elapsedSeconds = 0
        workoutWasStarted = false // Reset the flag when timer is reset
    }
    
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// Exercise tile component
struct ExerciseTile: View {
    let exercise: Exercise
    let onMore: () -> Void
    let onComplete: () -> Void
    
    // Use @State to track a local copy of the completion status for immediate UI feedback
    @State private var isCompleted: Bool
    
    // Initialize state from exercise
    init(exercise: Exercise, onMore: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.exercise = exercise
        self.onMore = onMore
        self.onComplete = onComplete
        // Initialize the local state from the exercise
        self._isCompleted = State(initialValue: exercise.isCompleted)
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                // Exercise name and details
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Exercise rep/set/duration info
                    HStack {
                        if let sets = exercise.sets {
                            Text("\(sets) sets")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        
                        if let reps = exercise.reps {
                            Text("• \(reps) reps")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                        
                        if let duration = exercise.duration {
                            Text("• \(duration)")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                        }
                    }
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 12) {
                    // Simple green checkbox
                    Button(action: {
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // Update local state immediately for UI feedback
                        isCompleted.toggle()
                        
                        // Call the completion handler
                        onComplete()
                    }) {
                        ZStack {
                            // The box - always green
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 30, height: 30)
                                .cornerRadius(8)
                            
                            // The checkmark - always visible
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // More button
                    Button(action: onMore) {
                        Text("More")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(14)
            .background(isCompleted ? Color.green.opacity(0.3) : Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCompleted ? Color.green : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        // Update local state whenever the exercise changes
        .onChange(of: exercise.isCompleted) { newValue in
            isCompleted = newValue
        }
    }
}

// Stats card component for exercise details
struct StatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
    }
} 
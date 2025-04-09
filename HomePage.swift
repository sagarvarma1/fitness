import SwiftUI
import UIKit

struct HomePage: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var navigateToWorkout = false
    @State private var showingError = false
    @State private var refreshID = UUID() // Add refresh ID to force view refresh
    @State private var showingWorkoutHistory = false // State for workout history sheet
    
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
                // Top navigation area with menu button and logo
                    HStack {
                        Button(action: {
                            showingWorkoutHistory = true
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        // Empty space for symmetry
                        Color.clear
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 20)
                    }
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
                
                // Setup notification observers
                setupNotificationObservers()
                
                // Force refresh
                self.refreshID = UUID()
            }
            .onDisappear {
                // Remove notification observer
                NotificationCenter.default.removeObserver(self)
            }
            .sheet(isPresented: $showingWorkoutHistory, onDismiss: {
                // Reload saved state when returning from history view
                viewModel.reloadSavedState()
                
                // Force the view to refresh
                self.refreshID = UUID()
            }) {
                WorkoutHistoryView(viewModel: viewModel)
            }
        }
    
    // Setup notification observers
    private func setupNotificationObservers() {
        // Refresh observer
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
        
        // Start workout observer
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StartCurrentWorkout"),
            object: nil,
            queue: .main
        ) { _ in
            print("Observer caught StartCurrentWorkout notification")
            // Trigger workout navigation
            self.navigateToWorkout = true
        }
    }
}

// Workout History View
struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedWorkout: WorkoutReference? = nil
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use the same background as the main app
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.workoutProgram == nil {
                    // Show loading indicator if program isn't loaded yet
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading workouts...")
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                } else {
                    // All workouts list
                    ScrollView {
                        LazyVStack(spacing: 0) { // Reduced spacing between all items
                            // Sort weeks by index/number rather than name to ensure correct order
                            let sortedWeekIndices = (0..<viewModel.workoutProgram!.weeks.count).sorted { 
                                // Extract week number from week name and sort numerically
                                let week1 = viewModel.workoutProgram!.weeks[$0]
                                let week2 = viewModel.workoutProgram!.weeks[$1]
                                
                                // Extract week numbers (assuming format "Week X - Description")
                                let week1Num = Int(week1.name.replacingOccurrences(of: "Week ", with: "").components(separatedBy: " ").first ?? "0") ?? 0
                                let week2Num = Int(week2.name.replacingOccurrences(of: "Week ", with: "").components(separatedBy: " ").first ?? "0") ?? 0
                                
                                return week1Num < week2Num
                            }
                            
                            // Group workouts by week using sorted indices
                            ForEach(sortedWeekIndices, id: \.self) { weekIndex in
                                let week = viewModel.workoutProgram!.weeks[weekIndex]
                                
                                // Week header
                                HStack {
                                    Text(week.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.leading, 5)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, weekIndex > 0 ? 5 : 5) // Reduced top padding
                                
                                // Days in this week
                                ForEach(0..<week.days.count, id: \.self) { dayIndex in
                                    let day = week.days[dayIndex]
                                    
                                    // Check if this workout has been completed
                                    let completedWorkout = viewModel.findCompletedWorkout(weekName: week.name, dayName: day.name)
                                    let isCurrentWorkout = weekIndex == viewModel.currentWeekIndex && dayIndex == viewModel.currentDayIndex
                                    let isFutureWorkout = (weekIndex > viewModel.currentWeekIndex) || 
                                                         (weekIndex == viewModel.currentWeekIndex && dayIndex > viewModel.currentDayIndex)
                                    
                                    NavigationLink(
                                        destination: WorkoutDetailView(
                                            viewModel: viewModel,
                                            workoutReference: WorkoutReference(
                                                weekIndex: weekIndex,
                                                dayIndex: dayIndex,
                                                completedWorkout: completedWorkout
                                            )
                                        )
                                    ) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(day.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
                                                Text(day.focus)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Status indicator
                                            Group {
                                                if let completed = completedWorkout {
                                                    // Completed workout
                                                    HStack(spacing: 5) {
                                                        Text("\(completed.completedExercises)/\(completed.totalExercises)")
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                        
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.green.opacity(0.2))
                                                    .cornerRadius(10)
                                                } else if isCurrentWorkout {
                                                    // Current workout
                                                    HStack(spacing: 5) {
                                                        Text("CURRENT")
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                        
                                                        Image(systemName: "flame.fill")
                                                            .foregroundColor(.red)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.red.opacity(0.2))
                                                    .cornerRadius(10)
                                                } else if isFutureWorkout {
                                                    // Future workout
                                                    HStack(spacing: 5) {
                                                        Text("UPCOMING")
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                        
                                                        Image(systemName: "clock")
                                                            .foregroundColor(.gray)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(10)
                                                } else {
                                                    // Missed workout
                                                    HStack(spacing: 5) {
                                                        Text("MISSED")
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                        
                                                        Image(systemName: "xmark.circle")
                                                            .foregroundColor(.orange)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.orange.opacity(0.2))
                                                    .cornerRadius(10)
                                                }
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 6) // Reduced vertical padding
                                        .padding(.horizontal)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                        .padding(.vertical, 2) // Reduced spacing between day items
                                    }
                                }
                            }
                            .padding(.bottom, 10) // Reduced bottom padding
                        }
                        .padding(.top, 5) // Reduced top padding
                    }
                }
            }
            .navigationTitle("All Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Reference to a workout (either completed or from the program)
struct WorkoutReference {
    let weekIndex: Int
    let dayIndex: Int
    let completedWorkout: CompletedWorkout?
    
    var isCompleted: Bool {
        return completedWorkout != nil
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
                        
                        // Save the workout with duration
                        viewModel.advanceToNextDay(duration: elapsedSeconds)
                        
                        // Use a flag for navigation instead of direct presentation
                        isPresented = false
                        
                        // Add slight delay before showing completion view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Post notification to refresh the home view
                            NotificationCenter.default.post(
                                name: NSNotification.Name("RefreshHomeView"),
                                object: nil
                            )
                            
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
        .onAppear {
            // Auto-start timer if this is a fresh workout session
            if !workoutWasStarted {
                startTimer()
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

// Workout Detail View - for viewing any workout (completed or future)
struct WorkoutDetailView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let workoutReference: WorkoutReference
    @Environment(\.presentationMode) var presentationMode
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise? = nil
    
    // Get the week and day from the reference
    private var week: Week? {
        guard let program = viewModel.workoutProgram,
              workoutReference.weekIndex < program.weeks.count else {
            return nil
        }
        return program.weeks[workoutReference.weekIndex]
    }
    
    private var day: Day? {
        guard let week = week,
              workoutReference.dayIndex < week.days.count else {
            return nil
        }
        return week.days[workoutReference.dayIndex]
    }
    
    // Computed properties for workout status
    private var isCompleted: Bool {
        return workoutReference.isCompleted
    }
    
    private var isCurrent: Bool {
        return workoutReference.weekIndex == viewModel.currentWeekIndex &&
               workoutReference.dayIndex == viewModel.currentDayIndex
    }
    
    private var isFuture: Bool {
        return (workoutReference.weekIndex > viewModel.currentWeekIndex) ||
               (workoutReference.weekIndex == viewModel.currentWeekIndex && 
                workoutReference.dayIndex > viewModel.currentDayIndex)
    }
    
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
            ScrollView {
                VStack(spacing: 10) { // Reduced overall spacing
                    if let week = week, let day = day {
                        // Close button - added to the top of the view instead of navigation bar
                        HStack {
                            Spacer()
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                        }
                        .padding(.top, 10)
                        
                        // App logo/icon instead of status tags
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        // Timer section for completed workouts only
                        if let completedWorkout = workoutReference.completedWorkout {
                            VStack(spacing: 5) {
                                Text("WORKOUT DURATION")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                
                                // Display completion time if available, otherwise "Unknown"
                                Text(completedWorkout.formattedDuration ?? "Unknown")
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                        
                        // Focus section
                        VStack(alignment: .leading, spacing: 5) {
                            Text("FOCUS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Text(day.focus)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(day.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Exercises list
                        Text("Exercises")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 6) { // Reduced spacing between exercise tiles
                            if isCompleted, let completedWorkout = workoutReference.completedWorkout {
                                // Show completed workout exercises but with disabled checkboxes
                                ForEach(completedWorkout.exercises) { exercise in
                                    WorkoutExerciseTile(
                                        exercise: exercise,
                                        onMore: {
                                            selectedExercise = exercise
                                            showingExerciseDetail = true
                                        },
                                        showCompletionColor: true
                                    )
                                    .padding(.horizontal)
                                }
                            } else {
                                // Show exercises from program without checkboxes
                                ForEach(day.exercises) { exercise in
                                    WorkoutExerciseTile(
                                        exercise: exercise,
                                        onMore: {
                                            selectedExercise = exercise
                                            showingExerciseDetail = true
                                        },
                                        showCompletionColor: false
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Add a start workout button ONLY for the current workout (not for completed)
                        if isCurrent && !isCompleted {
                            Button("START THIS WORKOUT") {
                                // Dismiss this view and post notification to start the workout
                                self.presentationMode.wrappedValue.dismiss()
                                
                                // Post a notification to start the workout
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("StartCurrentWorkout"),
                                        object: nil
                                    )
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(15)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 20)
                            .padding(.top, 10)
                        }
                    } else {
                        // Fallback view if data is missing
                        Text("Workout details not available")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Custom modal overlay for exercise details
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
        .navigationBarHidden(true) // Hide the navigation bar since we have our own X button
    }
}

// Simplified exercise tile for workout detail view (no checkbox)
struct WorkoutExerciseTile: View {
    let exercise: Exercise
    let onMore: () -> Void
    let showCompletionColor: Bool // Whether to show completion state colors
    
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
                
                // Only the More button
                Button(action: onMore) {
                    Text("More")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(14)
            .background(
                showCompletionColor ? 
                    (exercise.isCompleted ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) : 
                    Color.black.opacity(0.3)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        showCompletionColor ? 
                            (exercise.isCompleted ? Color.green : Color.red) : 
                            Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
    }
} 
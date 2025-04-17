import SwiftUI
import UIKit

struct HomePage: View {
    @EnvironmentObject private var viewModel: WorkoutViewModel
    @State private var navigateToWorkout = false
    @State private var showingError = false
    @State private var refreshID = UUID() // Add refresh ID to force view refresh
    @State private var showingWorkoutHistory = false // State for workout history sheet
    @State private var timeUntilNextWorkout: TimeInterval = 24 * 60 * 60 // Default 24 hours
    @State private var timer: Timer? = nil
    @State private var selectedMotivationalPhrase: String = "" // Store the selected phrase
    @State private var motivationalPhrases = [
        "Great job today!",
        "You crushed it!",
        "Well done!",
        "Awesome workout!",
        "You're killing it!",
        "Keep up the good work!",
        "Workout complete! You rock!",
        "Another one in the books!",
        "Your future self thanks you!"
    ]
    
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
                        
                        // Check if today's workout is completed AND if it was completed today
                        if let completedWorkout = findCurrentCompletedWorkout(), 
                           Calendar.current.isDateInToday(completedWorkout.completionDate) {
                            // Workout completed today - show the countdown timer view
                            workoutCompletedView()
                        } else {
                            // Workout not completed, or completed on a previous day (show next workout)
                            // Normal workout view - "GET STARTED" button
                            Button("GET STARTED") {
                                // Reset timer state in UserDefaults before starting workout
                                UserDefaults.standard.removeObject(forKey: "workoutTimerRunning")
                                UserDefaults.standard.removeObject(forKey: "workoutElapsedSeconds")
                                UserDefaults.standard.removeObject(forKey: "workoutWasStarted")
                                UserDefaults.standard.removeObject(forKey: "workoutStartTime")
                                
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
                                WorkoutProgressView(isPresented: $navigateToWorkout)
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
                
                // Reload workout data if needed
                if viewModel.workoutProgram == nil {
                    viewModel.loadWorkoutData()
                }
                
                // Always reload completed workouts
                viewModel.loadCompletedWorkouts()
                
                // Reload state to get the current day
                viewModel.reloadSavedState()
                
                // --- Automatic Unlock Logic --- 
                // Check if the current workout (based on saved state) is completed
                if let completedWorkout = findCurrentCompletedWorkout() {
                    // Check if the completion date was *before* today
                    if !Calendar.current.isDateInToday(completedWorkout.completionDate) {
                        print("Workout completed on a previous day. Unlocking next workout automatically.")
                        // Unlock the next workout (advances indices, resets timer)
                        unlockNextWorkout() 
                        // Note: unlockNextWorkout now handles refreshID and timer invalidation
                    }
                }
                // --- End Automatic Unlock Logic ---
                
                // Setup notification observers
                setupNotificationObservers()
                
                // Select motivational phrase if needed (only for the completed view)
                if let completedWorkout = findCurrentCompletedWorkout(), 
                   Calendar.current.isDateInToday(completedWorkout.completionDate) {
                    if selectedMotivationalPhrase.isEmpty {
                        selectMotivationalPhrase()
                    }
                    // Start the countdown timer only if workout completed today
                    startNextWorkoutTimer()
                } else {
                    // Ensure timer is stopped if workout isn't completed today
                    timer?.invalidate()
                    timer = nil
                }
                
                // Force refresh *after* potential unlock
                self.refreshID = UUID()
            }
            .onDisappear {
                // Remove notification observer
                NotificationCenter.default.removeObserver(self)
                
                // Invalidate timer
                timer?.invalidate()
                timer = nil
            }
            .sheet(isPresented: $showingWorkoutHistory, onDismiss: {
                // Reload saved state when returning from history view
                viewModel.reloadSavedState()
                
                // Force the view to refresh
                self.refreshID = UUID()
            }) {
                WorkoutHistoryView()
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
            // Reload completed workouts first
            viewModel.loadCompletedWorkouts()
            
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
        
        // Completed workout observer
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HideWorkoutCompletedView"),
            object: nil,
            queue: .main
        ) { _ in
            print("Observer caught HideWorkoutCompletedView notification")
            // Make sure to refresh completed workouts when returning from the completed view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.loadCompletedWorkouts()
                viewModel.reloadSavedState()
                self.refreshID = UUID()
            }
        }
    }
    
    // MARK: - Workout Completion UI
    
    // Helper to find the CompletedWorkout object for the *current* week/day
    private func findCurrentCompletedWorkout() -> CompletedWorkout? {
        guard let currentWeek = viewModel.currentWeek, let currentDay = viewModel.currentDay else {
            return nil
        }
        return viewModel.completedWorkouts.first { 
            $0.weekName == currentWeek.name && $0.dayName == currentDay.name 
        }
    }
    
    // Check if the current workout is completed
    private func isCurrentWorkoutCompleted() -> Bool {
        guard let currentWeek = viewModel.currentWeek, let currentDay = viewModel.currentDay else {
            return false
        }
        
        // Check if this workout exists in the completed workouts array
        return viewModel.completedWorkouts.contains { 
            $0.weekName == currentWeek.name && $0.dayName == currentDay.name 
        }
    }
    
    // Get the most recent completed workout
    private func getMostRecentCompletedWorkout() -> CompletedWorkout? {
        let sortedWorkouts = viewModel.completedWorkouts.sorted { $0.completionDate > $1.completionDate }
        return sortedWorkouts.first
    }
    
    // Calculate time until next workout (midnight today)
    private func calculateTimeUntilNextWorkout() {
        // Calculate time until midnight today
        let calendar = Calendar.current
        let now = Date()
        
        // Get midnight of the next day
        var components = DateComponents()
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        // Get date for tomorrow at midnight
        guard let midnight = calendar.date(byAdding: components, to: calendar.startOfDay(for: now)) else {
            timeUntilNextWorkout = 0
            return
        }
        
        // Calculate time remaining until midnight
        timeUntilNextWorkout = midnight.timeIntervalSince(now)
    }
    
    // Start timer to count down to next workout
    private func startNextWorkoutTimer() {
        // Calculate initial time
        calculateTimeUntilNextWorkout()
        
        // Stop existing timer if any
        timer?.invalidate()
        
        // Create new timer that updates every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            calculateTimeUntilNextWorkout()
            
            // If timer reaches zero, invalidate it and refresh view
            if timeUntilNextWorkout <= 0 {
                timer?.invalidate()
                timer = nil
                refreshID = UUID() // Force refresh
            }
        }
    }
    
    // Format the remaining time into a string
    private func formatTimeRemaining() -> String {
        let hours = Int(timeUntilNextWorkout) / 3600
        let minutes = (Int(timeUntilNextWorkout) % 3600) / 60
        let seconds = Int(timeUntilNextWorkout) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Select a random motivational phrase and store it
    private func selectMotivationalPhrase() {
        selectedMotivationalPhrase = motivationalPhrases.randomElement() ?? "Great job today!"
        
        // Store the phrase in UserDefaults so it persists across app restarts
        let defaults = UserDefaults.standard
        let lastWorkoutDate = getMostRecentCompletedWorkout()?.completionDate ?? Date()
        
        // Store both the phrase and the date it was selected
        defaults.set(selectedMotivationalPhrase, forKey: "selectedMotivationalPhrase")
        defaults.set(lastWorkoutDate, forKey: "motivationalPhraseDate")
    }
    
    // Get the selected motivational phrase
    private func getMotivationalPhrase() -> String {
        // If we already have a selected phrase, use it
        if !selectedMotivationalPhrase.isEmpty {
            return selectedMotivationalPhrase
        }
        
        // Otherwise, check if there's a stored phrase for today
        let defaults = UserDefaults.standard
        if let storedPhrase = defaults.string(forKey: "selectedMotivationalPhrase"),
           let storedDate = defaults.object(forKey: "motivationalPhraseDate") as? Date {
            
            // Only use the stored phrase if it's from the same day
            let calendar = Calendar.current
            if calendar.isDateInToday(storedDate) {
                selectedMotivationalPhrase = storedPhrase
                return storedPhrase
            }
        }
        
        // If no valid stored phrase, select a new one
        selectMotivationalPhrase()
        return selectedMotivationalPhrase
    }
    
    // The completed workout view
    private func workoutCompletedView() -> some View {
        VStack(spacing: 25) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
                .padding(.top, 20)
            
            // Congratulatory message - using the stored phrase instead of randomly generating one
            Text(getMotivationalPhrase())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Timer section
            VStack(spacing: 12) {
                Text("Next workout unlocks in")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(formatTimeRemaining())
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 25)
            .padding(.horizontal, 30)
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
            .padding(.horizontal, 30)
            
            // Unlock button
            Button(action: {
                // Unlock next workout immediately
                unlockNextWorkout()
            }) {
                HStack {
                    Image(systemName: "lock.open.fill")
                        .font(.headline)
                    Text("UNLOCK NOW")
                        .font(.headline)
                }
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
    }
    
    // Unlock the next workout
    private func unlockNextWorkout() {
        // Calculate the next workout indices
        guard let program = viewModel.workoutProgram else { return }
        
        let currentWeekIndex = viewModel.currentWeekIndex
        let currentDayIndex = viewModel.currentDayIndex
        
        // First try to advance to the next day in the current week
        if currentDayIndex < (viewModel.currentWeek?.days.count ?? 0) - 1 {
            // Next day in same week
            viewModel.currentDayIndex = currentDayIndex + 1
        }
        // If at the end of the week, advance to the next week
        else if currentWeekIndex < program.weeks.count - 1 {
            // First day of next week
            viewModel.currentWeekIndex = currentWeekIndex + 1
            viewModel.currentDayIndex = 0
        }
        // If at the end of the program, reset to the beginning
        else {
            viewModel.currentWeekIndex = 0
            viewModel.currentDayIndex = 0
        }
        
        // Save the new state immediately
        viewModel.saveState()
        
        // Reset the motivational phrase for the next workout
        selectedMotivationalPhrase = ""
        UserDefaults.standard.removeObject(forKey: "selectedMotivationalPhrase")
        
        // Invalidate timer and refresh the view
        timer?.invalidate()
        timer = nil
        refreshID = UUID()
    }
}

// Workout History View
struct WorkoutHistoryView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedWorkout: WorkoutReference? = nil
    @State private var showingWorkoutDetail = false
    @State private var showingResetConfirmation = false
    
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
                            // Sort weeks by number instead of name to ensure correct order
                            let sortedWeekIndices = (0..<viewModel.workoutProgram!.weeks.count).sorted { 
                                // Extract week number from week name and sort numerically
                                let week1 = viewModel.workoutProgram!.weeks[$0]
                                let week2 = viewModel.workoutProgram!.weeks[$1]
                                
                                // Extract week numbers (assuming format "Week X - Description")
                                let week1Num = extractWeekNumber(from: week1.name)
                                let week2Num = extractWeekNumber(from: week2.name)
                                
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
                        
                        // Add reset button at the bottom
                        Button(action: {
                            // Show confirmation dialog
                            showingResetConfirmation = true
                        }) {
                            Text("RESET")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.red)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .alert(isPresented: $showingResetConfirmation) {
                            Alert(
                                title: Text("Reset Everything"),
                                message: Text("This will reset ALL your workout progress, completed workouts, and timer data. This cannot be undone. Are you sure?"),
                                primaryButton: .destructive(Text("Reset Everything")) {
                                    // Hard reset everything
                                    
                                    // 1. Reset workout progress indices
                                    viewModel.resetProgress()
                                    
                                    // 2. Clear all timer state
                                    UserDefaults.standard.removeObject(forKey: "workoutTimerRunning")
                                    UserDefaults.standard.removeObject(forKey: "workoutElapsedSeconds")
                                    UserDefaults.standard.removeObject(forKey: "workoutWasStarted")
                                    UserDefaults.standard.removeObject(forKey: "workoutStartTime")
                                    
                                    // 3. Clear completed workouts
                                    viewModel.clearCompletedWorkouts()
                                    
                                    // 4. Reset exercise completion state
                                    UserDefaults.standard.removeObject(forKey: "exerciseCompletionStatus")
                                    
                                    // 5. Reload workout data, which will reset all exercises
                                    viewModel.loadWorkoutData()
                                    
                                    // 6. Reload state to reflect the changes immediately
                                    viewModel.reloadSavedState()
                                    
                                    // Dismiss the view after resetting
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
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
            // Apply black navigation bar appearance
            .onAppear {
                configureNavigationBarAppearance()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Configure the navigation bar appearance to match the app's dark theme
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    // Helper function to extract the week number from a week name
    private func extractWeekNumber(from weekName: String) -> Int {
        // Extract number from strings like "Week 1", "Week 10 - Title"
        let pattern = "Week (\\d+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        if let match = regex?.firstMatch(in: weekName, options: [], range: NSRange(location: 0, length: weekName.count)),
           let range = Range(match.range(at: 1), in: weekName) {
            let numberStr = String(weekName[range])
            return Int(numberStr) ?? 0
        }
        return 0
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
    @EnvironmentObject var viewModel: WorkoutViewModel
    @Binding var isPresented: Bool
    
    // Timer state
    @State private var isTimerRunning = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    @State private var workoutWasStarted = false // Track if workout was previously started
    @State private var startTime: Date? = nil
    @State private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    // Countdown state
    @State private var isCountingDown = false
    @State private var countdownValue = 3
    
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
                // Close button - only show if workout hasn't started yet
                if !workoutWasStarted {
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
                } else {
                    // Just show the flame when workout has started (no X button)
                    HStack {
                        Spacer()
                        
                        // Add fire logo
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
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
                        Button(action: {
                            if isTimerRunning {
                                stopTimer()
                            } else {
                                startCountdown()
                            }
                        }) {
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
                        .disabled(isCountingDown) // Disable button during countdown
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
                        
                        // Reset the timer state in UserDefaults
                        UserDefaults.standard.removeObject(forKey: "workoutTimerRunning")
                        UserDefaults.standard.removeObject(forKey: "workoutElapsedSeconds")
                        UserDefaults.standard.removeObject(forKey: "workoutWasStarted")
                        UserDefaults.standard.removeObject(forKey: "workoutStartTime")
                        
                        // Record the workout as completed
                        viewModel.recordWorkoutAsCompleted(duration: elapsedSeconds)
                        
                        // Post notification to refresh data in the background
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RefreshHomeView"),
                            object: nil
                        )
                        
                        // Immediately transition to completed view without dismissing first
                        // This prevents the home page from showing briefly
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowWorkoutCompletedView"),
                            object: nil
                        )
                        
                        // Dismiss after a slight delay to ensure the notification is processed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
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
            
            // Countdown overlay
            if isCountingDown {
                // Semi-transparent overlay
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                // Countdown text
                Text(countdownValue > 0 ? "\(countdownValue)" : "GO!")
                    .font(.system(size: 150, weight: .bold))
                    .foregroundColor(.red)
                    .transition(.scale)
                    .id("countdown-\(countdownValue)") // Force animation to refresh
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
            // Check if timer was running when the app was closed
            loadTimerState()
        }
        .onDisappear {
            // No longer stop the timer when view disappears
            // Instead, we'll save the timer state
            saveTimerState()
        }
        // Add scene phase change listeners
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App is going to background
            saveTimerState()
            startBackgroundTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // App is coming back to foreground
            if backgroundTaskIdentifier != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                backgroundTaskIdentifier = .invalid
            }
            updateTimerFromSavedState()
        }
    }
    
    // Timer functions
    private func startTimer() {
        isTimerRunning = true
        workoutWasStarted = true // Set the flag that workout has been started
        
        // Save the start time if it's not already set
        if startTime == nil {
            startTime = Date().addingTimeInterval(TimeInterval(-elapsedSeconds))
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = startTime {
                elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            } else {
                elapsedSeconds += 1
            }
        }
        
        // Save timer state
        saveTimerState()
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        // Note: We don't reset workoutWasStarted here, so we can show "Continue Workout"
        // Don't reset start time, we'll keep it for persisting workout duration
        
        // Save timer state
        saveTimerState()
    }
    
    private func resetTimer() {
        stopTimer()
        elapsedSeconds = 0
        workoutWasStarted = false // Reset the flag when timer is reset
        startTime = nil
        
        // Save timer state
        saveTimerState()
    }
    
    // Background task support
    private func startBackgroundTask() {
        if isTimerRunning {
            // Start a background task if timer is running
            backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
                // This is the expiration handler if we take too long
                if self.backgroundTaskIdentifier != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                    self.backgroundTaskIdentifier = .invalid
                }
            }
        }
    }
    
    // Persistence functions
    private func saveTimerState() {
        let defaults = UserDefaults.standard
        defaults.set(isTimerRunning, forKey: "workoutTimerRunning")
        defaults.set(elapsedSeconds, forKey: "workoutElapsedSeconds")
        defaults.set(workoutWasStarted, forKey: "workoutWasStarted")
        
        if let startTime = startTime {
            defaults.set(startTime, forKey: "workoutStartTime")
        } else {
            defaults.removeObject(forKey: "workoutStartTime")
        }
    }
    
    private func loadTimerState() {
        let defaults = UserDefaults.standard
        workoutWasStarted = defaults.bool(forKey: "workoutWasStarted")
        
        if workoutWasStarted {
            if let savedStartTime = defaults.object(forKey: "workoutStartTime") as? Date {
                startTime = savedStartTime
                
                // Calculate elapsed seconds based on saved start time
                elapsedSeconds = Int(Date().timeIntervalSince(startTime!))
                
                // If timer was running when app was closed, restart it
                if defaults.bool(forKey: "workoutTimerRunning") {
                    startTimer()
                } else {
                    // Just update the elapsed seconds based on the saved value
                    elapsedSeconds = defaults.integer(forKey: "workoutElapsedSeconds")
                }
            } else {
                // Fallback to just the saved elapsed seconds if no start time
                elapsedSeconds = defaults.integer(forKey: "workoutElapsedSeconds")
            }
        }
    }
    
    private func updateTimerFromSavedState() {
        if isTimerRunning, let startTime = startTime {
            // Update elapsed time from the persistent start time
            elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        }
    }
    
    // New countdown function
    private func startCountdown() {
        isCountingDown = true
        countdownValue = 3
        
        // Haptic feedback for the initial "3"
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Delay before first countdown to ensure "3" is visible for a full second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // First countdown: 3 -> 2
            generator.impactOccurred()
            self.countdownValue = 2
            
            // Second countdown: 2 -> 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generator.impactOccurred()
                self.countdownValue = 1
                
                // Third countdown: 1 -> GO!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    generator.impactOccurred()
                    self.countdownValue = 0 // GO!
                    
                    // After GO! show for 0.75 seconds, start the workout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        self.isCountingDown = false
                        self.startTimer() // Start the actual workout timer
                    }
                }
            }
        }
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
    @EnvironmentObject var viewModel: WorkoutViewModel
    let workoutReference: WorkoutReference
    @Environment(\.presentationMode) var presentationMode
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise? = nil
    
    // Photo states
    @State private var workoutPhoto: UIImage? = nil
    @State private var isLoadingPhoto = false
    @State private var showingPhotoOptions = false
    @State private var showingImagePicker = false
    @State private var showingFullScreenPhoto = false
    @State private var sourceType: UIImagePickerController.SourceType? = nil
    
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
                        // App logo/icon instead of status tags
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                            .padding(.top, 50) // Added padding to account for fixed X button
                        
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
                            
                            // Photo section (only for completed workouts) - moved below workout duration
                            if let photo = workoutPhoto {
                                // Show the workout photo as a square
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200) // Square dimensions
                                    .clipped()
                                    .cornerRadius(15)
                                    .padding(.top, 10)
                                    .onTapGesture {
                                        self.showingFullScreenPhoto = true
                                    }
                            } else if isLoadingPhoto {
                                // Show loading indicator while photo is loading
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Loading photo...")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .padding(.top, 5)
                                }
                                .frame(width: 200, height: 200) // Square dimensions
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(15)
                                .padding(.top, 10)
                            } else {
                                // Show upload button if no photo is available
                                Button(action: {
                                    self.showingPhotoOptions = true
                                }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                        
                                        Text("Upload Photo")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 200, height: 200) // Square dimensions
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(15)
                                }
                                .padding(.top, 10)
                            }
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
                                // Reset timer state in UserDefaults before starting workout
                                UserDefaults.standard.removeObject(forKey: "workoutTimerRunning")
                                UserDefaults.standard.removeObject(forKey: "workoutElapsedSeconds")
                                UserDefaults.standard.removeObject(forKey: "workoutWasStarted")
                                UserDefaults.standard.removeObject(forKey: "workoutStartTime")
                                
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
                            .padding(.top, 50) // Added padding to account for fixed X button
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Fixed close button overlay that stays visible when scrolling
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                Spacer()
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
            
            // Full screen photo overlay
            if showingFullScreenPhoto, let photo = workoutPhoto {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Close button in the top-right corner
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                self.showingFullScreenPhoto = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(15)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(20)
                        }
                        
                        Spacer()
                    }
                }
                .transition(.opacity)
                .zIndex(2)
                .onTapGesture {
                    self.showingFullScreenPhoto = false
                }
            }
        }
        .navigationBarHidden(true) // Hide the navigation bar since we have our own X button
        .onAppear {
            // Load the photo if the workout has one
            if let completedWorkout = workoutReference.completedWorkout, let photoID = completedWorkout.photoID {
                self.isLoadingPhoto = true
                viewModel.getWorkoutPhoto(photoID: photoID) { image in
                    self.workoutPhoto = image
                    self.isLoadingPhoto = false
                }
            }
        }
        .sheet(isPresented: $showingPhotoOptions) {
            ImagePickerSelectionView(
                selectedImage: $workoutPhoto,
                isPresented: $showingPhotoOptions,
                sourceType: $sourceType
            )
        }
        .sheet(item: $sourceType) { sourceType in
            CameraOrLibraryPicker(
                selectedImage: $workoutPhoto,
                sourceType: sourceType
            )
            .onDisappear {
                // Save the photo if selected
                if let photo = workoutPhoto, let completedWorkout = workoutReference.completedWorkout {
                    // Upload to CloudKit
                    viewModel.saveWorkoutPhoto(workoutID: completedWorkout.id, image: photo) { photoID in
                        // Photo saved, no action needed as the workout was already updated by the ViewModel
                    }
                }
            }
        }
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
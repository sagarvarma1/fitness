import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    @Published var workoutProgram: WorkoutProgram?
    @Published var currentWeekIndex: Int = 0 {
        didSet {
            saveState()
        }
    }
    @Published var currentDayIndex: Int = 0 {
        didSet {
            saveState()
        }
    }
    @Published var loadingError: String? = nil
    @Published var completedWorkouts: [CompletedWorkout] = []
    
    init() {
        // First, load the workout data
        loadWorkoutData()
        // Then load the saved state or initialize to defaults
        loadSavedState()
        // Load completed workouts history
        loadCompletedWorkouts()
    }
    
    // Load saved user progress
    private func loadSavedState() {
        let defaults = UserDefaults.standard
        
        // Check if first launch (using a static key unrelated to index values)
        if defaults.bool(forKey: "hasCompletedInitialSetup") {
            // Not first launch, load saved indices
            self.currentWeekIndex = defaults.integer(forKey: "currentWeekIndex")
            self.currentDayIndex = defaults.integer(forKey: "currentDayIndex")
            
            // Load exercise completion status
            if let workoutProgram = self.workoutProgram {
                loadExerciseCompletionStatus(workoutProgram: workoutProgram)
            }
            
            print("Loaded saved state: Week \(currentWeekIndex), Day \(currentDayIndex)")
        } else {
            // First launch, initialize to defaults
            self.currentWeekIndex = 0
            self.currentDayIndex = 0
            
            // Mark as initialized
            defaults.set(true, forKey: "hasCompletedInitialSetup")
            
            // Save the initial state
            saveState()
            print("First launch: Initialized to Week 0, Day 0")
        }
    }
    
    // Save current progress
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(self.currentWeekIndex, forKey: "currentWeekIndex")
        defaults.set(self.currentDayIndex, forKey: "currentDayIndex")
        
        // Save exercise completion status for the current workout
        if let workoutProgram = self.workoutProgram {
            saveExerciseCompletionStatus(workoutProgram: workoutProgram)
        }
        
        print("Saved state: Week \(currentWeekIndex), Day \(currentDayIndex)")
    }
    
    // Save exercise completion status to UserDefaults
    private func saveExerciseCompletionStatus(workoutProgram: WorkoutProgram) {
        let defaults = UserDefaults.standard
        
        var completionData: [String: Bool] = [:]
        
        // Iterate through all weeks, days, and exercises to save completion status
        for (weekIndex, week) in workoutProgram.weeks.enumerated() {
            for (dayIndex, day) in week.days.enumerated() {
                for (exerciseIndex, exercise) in day.exercises.enumerated() {
                    // Create a unique key for each exercise
                    let key = "exercise_\(weekIndex)_\(dayIndex)_\(exerciseIndex)"
                    completionData[key] = exercise.isCompleted
                }
            }
        }
        
        defaults.set(completionData, forKey: "exerciseCompletionStatus")
    }
    
    // Load exercise completion status from UserDefaults
    private func loadExerciseCompletionStatus(workoutProgram: WorkoutProgram) {
        let defaults = UserDefaults.standard
        
        guard let completionData = defaults.dictionary(forKey: "exerciseCompletionStatus") as? [String: Bool] else {
            return
        }
        
        // Create a new array of weeks
        var updatedWeeks: [Week] = []
        
        // Iterate through all weeks, days, and exercises to load completion status
        for (weekIndex, week) in workoutProgram.weeks.enumerated() {
            // Create a new array of days for this week
            var updatedDays: [Day] = []
            
            for (dayIndex, day) in week.days.enumerated() {
                // Create a new array of exercises for this day
                var updatedExercises: [Exercise] = []
                
                for (exerciseIndex, exercise) in day.exercises.enumerated() {
                    let key = "exercise_\(weekIndex)_\(dayIndex)_\(exerciseIndex)"
                    
                    let isCompleted = completionData[key] ?? exercise.isCompleted
                    
                    // Create a new exercise with updated completion status
                    let updatedExercise = Exercise(
                        title: exercise.title,
                        description: exercise.description,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        weight: exercise.weight,
                        duration: exercise.duration,
                        isCompleted: isCompleted
                    )
                    
                    updatedExercises.append(updatedExercise)
                }
                
                // Create a new day with updated exercises
                let updatedDay = Day(
                    name: day.name,
                    focus: day.focus,
                    description: day.description,
                    exercises: updatedExercises
                )
                
                updatedDays.append(updatedDay)
            }
            
            // Create a new week with updated days
            let updatedWeek = Week(
                name: week.name,
                days: updatedDays
            )
            
            updatedWeeks.append(updatedWeek)
        }
        
        // Create a new program with updated weeks
        self.workoutProgram = WorkoutProgram(weeks: updatedWeeks)
    }
    
    // Load completed workouts from UserDefaults
    private func loadCompletedWorkouts() {
        let defaults = UserDefaults.standard
        
        if let savedData = defaults.data(forKey: "completedWorkoutsHistory") {
            let decoder = JSONDecoder()
            if let decodedWorkouts = try? decoder.decode([CompletedWorkout].self, from: savedData) {
                self.completedWorkouts = decodedWorkouts
            }
        }
    }
    
    // Save completed workouts to UserDefaults
    private func saveCompletedWorkouts() {
        let defaults = UserDefaults.standard
        
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(completedWorkouts) {
            defaults.set(encodedData, forKey: "completedWorkoutsHistory")
        }
    }
    
    // Reload state from UserDefaults
    func reloadSavedState() {
        let defaults = UserDefaults.standard
        
        // First reload the completed workouts
        loadCompletedWorkouts()
        
        if defaults.bool(forKey: "hasCompletedInitialSetup") {
            // Load the saved indices
            self.currentWeekIndex = defaults.integer(forKey: "currentWeekIndex")
            self.currentDayIndex = defaults.integer(forKey: "currentDayIndex")
            
            // Load exercise completion status if workout program is loaded
            if let workoutProgram = self.workoutProgram {
                loadExerciseCompletionStatus(workoutProgram: workoutProgram)
                
                // Check if there's a mismatch between completed workouts and current day
                updateCurrentDayBasedOnCompletedWorkouts(workoutProgram: workoutProgram)
            }
            
            print("Reloaded state: Week \(currentWeekIndex), Day \(currentDayIndex)")
            
            // Force refresh of the published properties
            self.objectWillChange.send()
        }
    }
    
    // New method to ensure currentDay is updated based on completed workouts
    private func updateCurrentDayBasedOnCompletedWorkouts(workoutProgram: WorkoutProgram) {
        guard !completedWorkouts.isEmpty else { return }
        
        // If we have the current week and day loaded and the current day is completed,
        // we should move to the next day
        if let currentWeek = self.currentWeek, let currentDay = self.currentDay {
            if isWorkoutCompleted(weekName: currentWeek.name, dayName: currentDay.name) {
                // This day is completed, so we should advance to the next day
                if currentDayIndex < currentWeek.days.count - 1 {
                    // Next day in same week
                    currentDayIndex += 1
                    saveState()
                    print("Advanced to next day: \(currentDayIndex) in same week")
                } else if currentWeekIndex < workoutProgram.weeks.count - 1 {
                    // First day of next week
                    currentWeekIndex += 1
                    currentDayIndex = 0
                    saveState()
                    print("Advanced to first day of next week: \(currentWeekIndex)")
                }
            }
        }
    }
    
    // Helper method to check if a workout is completed
    private func isWorkoutCompleted(weekName: String, dayName: String) -> Bool {
        return completedWorkouts.contains { $0.weekName == weekName && $0.dayName == dayName }
    }
    
    func loadWorkoutData() {
        self.loadingError = nil
        
        do {
            // Get the path to the workouts.json file
            guard let path = Bundle.main.path(forResource: "workouts", ofType: "json") else {
                self.loadingError = "Could not find workouts.json in the app bundle"
                print(self.loadingError!)
                return
            }
            
            // Read the file data
            let fileUrl = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: fileUrl)
            
            // Decode the JSON
            let decoder = JSONDecoder()
            self.workoutProgram = try decoder.decode(WorkoutProgram.self, from: data)
            
            // Load exercise completion status
            loadExerciseCompletionStatus(workoutProgram: self.workoutProgram!)
            
            print("Successfully loaded workout data")
        } catch {
            self.loadingError = "Error decoding workouts.json: \(error)"
            print(self.loadingError!)
        }
    }
    
    // Get the current week
    var currentWeek: Week? {
        guard let program = workoutProgram, !program.weeks.isEmpty, currentWeekIndex < program.weeks.count else {
            return nil
        }
        return program.weeks[currentWeekIndex]
    }
    
    // Get the current day
    var currentDay: Day? {
        guard let week = currentWeek, !week.days.isEmpty, currentDayIndex < week.days.count else {
            return nil
        }
        return week.days[currentDayIndex]
    }
    
    // Get exercise titles for the current day
    var currentExerciseTitles: [String] {
        guard let day = currentDay else {
            return []
        }
        return day.exercises.map { $0.title }
    }
    
    // Advance to the next day and record the completed workout
    func advanceToNextDay(duration: Int? = nil) {
        guard let program = workoutProgram, let currentWeek = self.currentWeek, let currentDay = self.currentDay else { return }
        
        // Create a record of the completed workout
        let completedWorkout = CompletedWorkout(
            weekName: currentWeek.name,
            dayName: currentDay.name,
            completionDate: Date(),
            exercises: currentDay.exercises,
            duration: duration
        )
        
        // Add to completed workouts history
        completedWorkouts.append(completedWorkout)
        saveCompletedWorkouts()
        
        // First try to advance to the next day in the current week
        if currentDayIndex < currentWeek.days.count - 1 {
            currentDayIndex += 1
        }
        // If at the end of the week, advance to the next week
        else if currentWeekIndex < program.weeks.count - 1 {
            currentWeekIndex += 1
            currentDayIndex = 0
        }
        // If at the end of the program, reset to the beginning
        else {
            currentWeekIndex = 0
            currentDayIndex = 0
        }
        
        // State is saved automatically in the didSet property observers
    }
    
    // Reset progress if needed
    func resetProgress() {
        currentWeekIndex = 0
        currentDayIndex = 0
    }
    
    // Toggle exercise completion status
    func toggleExerciseCompletion(exerciseIndex: Int) {
        guard let workoutProgram = self.workoutProgram,
              let currentWeek = self.currentWeek,
              let currentDay = self.currentDay,
              exerciseIndex < currentDay.exercises.count else { return }
        
        // Get the current exercise and toggle its completion status
        let currentExercise = currentDay.exercises[exerciseIndex]
        let updatedExercise = Exercise(
            title: currentExercise.title,
            description: currentExercise.description,
            sets: currentExercise.sets,
            reps: currentExercise.reps,
            weight: currentExercise.weight,
            duration: currentExercise.duration,
            isCompleted: !currentExercise.isCompleted
        )
        
        // Create a new array of exercises with the updated exercise
        var updatedExercises: [Exercise] = []
        for (index, exercise) in currentDay.exercises.enumerated() {
            if index == exerciseIndex {
                updatedExercises.append(updatedExercise)
            } else {
                updatedExercises.append(exercise)
            }
        }
        
        // Create a new day with the updated exercises
        let updatedDay = Day(
            name: currentDay.name,
            focus: currentDay.focus,
            description: currentDay.description,
            exercises: updatedExercises
        )
        
        // Create a new array of days with the updated day
        var updatedDays: [Day] = []
        for (index, day) in currentWeek.days.enumerated() {
            if index == currentDayIndex {
                updatedDays.append(updatedDay)
            } else {
                updatedDays.append(day)
            }
        }
        
        // Create a new week with the updated days
        let updatedWeek = Week(
            name: currentWeek.name,
            days: updatedDays
        )
        
        // Create a new array of weeks with the updated week
        var updatedWeeks: [Week] = []
        for (index, week) in workoutProgram.weeks.enumerated() {
            if index == currentWeekIndex {
                updatedWeeks.append(updatedWeek)
            } else {
                updatedWeeks.append(week)
            }
        }
        
        // Create a new program with the updated weeks
        self.workoutProgram = WorkoutProgram(weeks: updatedWeeks)
        
        // Save the updated exercise completion status
        saveState()
        
        // Update state
        objectWillChange.send()
    }
    
    // Find a completed workout by week and day name
    func findCompletedWorkout(weekName: String, dayName: String) -> CompletedWorkout? {
        return completedWorkouts.first { 
            $0.weekName == weekName && $0.dayName == dayName 
        }
    }
} 
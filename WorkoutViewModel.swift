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
    
    init() {
        // First, load the workout data
        loadWorkoutData()
        // Then load the saved state or initialize to defaults
        loadSavedState()
    }
    
    // Load saved user progress
    private func loadSavedState() {
        let defaults = UserDefaults.standard
        
        // Check if first launch (using a static key unrelated to index values)
        if defaults.bool(forKey: "hasCompletedInitialSetup") {
            // Not first launch, load saved indices
            self.currentWeekIndex = defaults.integer(forKey: "currentWeekIndex")
            self.currentDayIndex = defaults.integer(forKey: "currentDayIndex")
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
        print("Saved state: Week \(currentWeekIndex), Day \(currentDayIndex)")
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
    
    // Advance to the next day
    func advanceToNextDay() {
        guard let program = workoutProgram, let week = currentWeek else { return }
        
        // First try to advance to the next day in the current week
        if currentDayIndex < week.days.count - 1 {
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
} 
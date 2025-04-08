import Foundation
import SwiftUI

class WorkoutViewModel: ObservableObject {
    @Published var workoutProgram: WorkoutProgram?
    @Published var currentWeekIndex: Int = 0
    @Published var currentDayIndex: Int = 0
    
    init() {
        loadWorkoutData()
    }
    
    // Make this function public so it can be called from HomePage
    func loadWorkoutData() {
        workoutProgram = WorkoutProgram.loadFromJSON()
    }
    
    // Get the current week
    var currentWeek: Week? {
        guard let program = workoutProgram, currentWeekIndex < program.weeks.count else {
            return nil
        }
        return program.weeks[currentWeekIndex]
    }
    
    // Get the current day
    var currentDay: Day? {
        guard let week = currentWeek, currentDayIndex < week.days.count else {
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
        guard let program = workoutProgram else { return }
        
        // First try to advance to the next day in the current week
        if let week = currentWeek, currentDayIndex < week.days.count - 1 {
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
    }
} 
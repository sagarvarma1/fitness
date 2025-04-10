import Foundation

// Updated models to match the actual JSON structure
struct WorkoutProgram: Codable {
    let weeks: [Week]
    
    // Standard initializer
    init(weeks: [Week]) {
        self.weeks = weeks
    }
    
    // Custom decoder to handle the dictionary format in the JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let weeksDict = try container.decode([String: [String: DayData]].self)
        
        // Extract week number helper function (defined outside to avoid capturing self)
        func extractWeekNumber(from weekName: String) -> Int {
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
        
        // Convert dictionary to our model structure
        var unsortedWeeks = weeksDict.map { weekName, daysDict in
            let days = daysDict.map { dayName, dayData in
                Day(name: dayName, focus: dayData.Focus, description: dayData.Description, exercises: dayData.Exercises)
            }.sorted { $0.name < $1.name } // Sort days
            
            return Week(name: weekName, days: days)
        }
        
        // Sort weeks by week number
        unsortedWeeks.sort { 
            let week1Num = extractWeekNumber(from: $0.name)
            let week2Num = extractWeekNumber(from: $1.name)
            return week1Num < week2Num
        }
        
        // Initialize the weeks array
        self.weeks = unsortedWeeks
    }
}

struct Week: Codable, Identifiable {
    var id = UUID()
    let name: String
    let days: [Day]
}

struct Day: Codable, Identifiable {
    var id = UUID()
    let name: String
    let focus: String
    let description: String
    let exercises: [Exercise]
}

// Structure to match the raw JSON format
struct DayData: Codable {
    let Focus: String
    let Description: String
    let Exercises: [Exercise]
}

struct Exercise: Codable, Identifiable {
    var id = UUID()
    let title: String
    let description: String?
    let sets: Int?
    let reps: Int?
    let weight: String?
    let duration: String?
    var isCompleted: Bool = false
    
    // Add flexible decoding for reps which might be Int or String
    enum CodingKeys: String, CodingKey {
        case title, description, sets, reps, weight, duration, isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        
        // Handle reps that could be Int or String
        if let repsInt = try? container.decodeIfPresent(Int.self, forKey: .reps) {
            reps = repsInt
        } else {
            reps = nil
        }
        
        weight = try container.decodeIfPresent(String.self, forKey: .weight)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
    
    init(title: String, description: String?, sets: Int?, reps: Int?, weight: String? = nil, duration: String? = nil, isCompleted: Bool = false) {
        self.title = title
        self.description = description
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.isCompleted = isCompleted
    }
}

// Model for storing completed workout history
struct CompletedWorkout: Codable, Identifiable {
    var id = UUID()
    let weekName: String
    let dayName: String
    let completionDate: Date
    let exercises: [Exercise]
    let duration: Int? // Duration in seconds, if recorded
    let photoID: String? // CloudKit record ID or reference for the workout photo
    
    // Calculate statistics about the workout
    var totalExercises: Int {
        return exercises.count
    }
    
    var completedExercises: Int {
        return exercises.filter { $0.isCompleted }.count
    }
    
    // Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }
    
    // Format duration for display
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // For Codable support with UUID
    enum CodingKeys: String, CodingKey {
        case id, weekName, dayName, completionDate, exercises, duration, photoID
    }
    
    init(weekName: String, dayName: String, completionDate: Date, exercises: [Exercise], duration: Int? = nil, photoID: String? = nil) {
        self.weekName = weekName
        self.dayName = dayName
        self.completionDate = completionDate
        self.exercises = exercises
        self.duration = duration
        self.photoID = photoID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        self.id = UUID(uuidString: idString) ?? UUID()
        self.weekName = try container.decode(String.self, forKey: .weekName)
        self.dayName = try container.decode(String.self, forKey: .dayName)
        self.completionDate = try container.decode(Date.self, forKey: .completionDate)
        self.exercises = try container.decode([Exercise].self, forKey: .exercises)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        self.photoID = try container.decodeIfPresent(String.self, forKey: .photoID)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(weekName, forKey: .weekName)
        try container.encode(dayName, forKey: .dayName)
        try container.encode(completionDate, forKey: .completionDate)
        try container.encode(exercises, forKey: .exercises)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(photoID, forKey: .photoID)
    }
}

// Extension to decode the workout program
extension WorkoutProgram {
    static func loadFromJSON() -> WorkoutProgram? {
        guard let url = Bundle.main.url(forResource: "workouts", withExtension: "json") else {
            print("Could not find workouts.json in the app bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(WorkoutProgram.self, from: data)
        } catch {
            print("Error decoding workouts.json: \(error)")
            return nil
        }
    }
} 
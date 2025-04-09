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
        
        // Convert dictionary to our model structure
        self.weeks = weeksDict.map { weekName, daysDict in
            let days = daysDict.map { dayName, dayData in
                Day(name: dayName, focus: dayData.Focus, description: dayData.Description, exercises: dayData.Exercises)
            }.sorted { $0.name < $1.name } // Sort days
            
            return Week(name: weekName, days: days)
        }.sorted { $0.name < $1.name } // Sort weeks
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
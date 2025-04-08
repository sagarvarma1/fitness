import Foundation

struct WorkoutProgram: Codable {
    let weeks: [Week]
}

struct Week: Codable {
    let name: String
    let days: [Day]
}

struct Day: Codable {
    let name: String
    let focus: String
    let exercises: [Exercise]
}

struct Exercise: Codable {
    let title: String
    let description: String?
    let sets: Int?
    let reps: String?
    let weight: String?
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
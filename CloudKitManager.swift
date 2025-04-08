import SwiftUI
import CloudKit

// Record type names for CloudKit database
enum RecordType: String {
    case userProgress = "UserProgress"
    case workoutPhoto = "WorkoutPhoto"
}

// CloudKit manager to handle CloudKit operations
class CloudKitManager: ObservableObject {
    // The CloudKit container
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    
    // Published properties to track loading states and errors
    @Published var isLoading = false
    @Published private(set) var error: Error? {
        didSet {
            if let error = error {
                errorHandler?(error)
            }
        }
    }
    
    // Error handler closure
    var errorHandler: ((Error) -> Void)?
    
    init() {
        // Initialize with the default container
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    // Save a photo to CloudKit
    func savePhoto(image: UIImage, isInitial: Bool, day: Int = 0, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        #if DEBUG
        // In development mode, attempt to create the schema if needed
        let recordType = RecordType.workoutPhoto.rawValue
        checkAndCreateRecordTypeIfNeeded(recordType: recordType) { success in
            if success {
                self.savePhotoActual(image: image, isInitial: isInitial, day: day, completion: completion)
            } else {
                let error = NSError(domain: "CloudKitManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create schema"])
                completion(.failure(error))
            }
        }
        #else
        // In production, assume schema exists
        savePhotoActual(image: image, isInitial: isInitial, day: day, completion: completion)
        #endif
    }
    
    // Now add a new actual save method that's called after schema check
    private func savePhotoActual(image: UIImage, isInitial: Bool, day: Int = 0, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        isLoading = true
        
        // Convert UIImage to compressed data
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            let error = NSError(domain: "CloudKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            completion(.failure(error))
            isLoading = false
            return
        }
        
        // Create a new record
        let record = CKRecord(recordType: RecordType.workoutPhoto.rawValue)
        
        // Create an asset from the image data
        let imageAsset = CKAsset(fileURL: saveImageTemporarily(data: imageData))
        
        // Set record values
        record["photo"] = imageAsset
        record["isInitial"] = isInitial
        record["day"] = day
        record["timestamp"] = Date()
        
        // Save the record to the database
        privateDB.save(record) { (savedRecord, error) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let savedRecord = savedRecord else {
                    let error = NSError(domain: "CloudKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save record"])
                    self.error = error
                    completion(.failure(error))
                    return
                }
                
                completion(.success(savedRecord))
                
                // Delete the temporary file
                if let asset = savedRecord["photo"] as? CKAsset, let fileURL = asset.fileURL {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
    }
    
    // Fetch the initial photo from CloudKit
    func fetchInitialPhoto(completion: @escaping (Result<UIImage?, Error>) -> Void) {
        // Create a predicate for initial photos
        let predicate = NSPredicate(format: "isInitial == %@", NSNumber(value: true))
        let query = CKQuery(recordType: RecordType.workoutPhoto.rawValue, predicate: predicate)
        
        // Sort by timestamp, most recent first
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        // Perform the query
        privateDB.perform(query, inZoneWith: nil) { [weak self] (records, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let records = records, !records.isEmpty else {
                    // No error, but no records found
                    completion(.success(nil))
                    return
                }
                
                // Get the most recent initial photo
                guard let asset = records[0]["photo"] as? CKAsset, let fileURL = asset.fileURL else {
                    let error = NSError(domain: "CloudKitManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid photo data"])
                    self?.error = error
                    completion(.failure(error))
                    return
                }
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    guard let image = UIImage(data: data) else {
                        throw NSError(domain: "CloudKitManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
                    }
                    completion(.success(image))
                } catch {
                    self?.error = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Fetch photos for a specific day
    func fetchPhotosForDay(day: Int, completion: @escaping (Result<[UIImage], Error>) -> Void) {
        isLoading = true
        
        // Create a predicate for photos from a specific day
        let predicate = NSPredicate(format: "day == %@", NSNumber(value: day))
        let query = CKQuery(recordType: RecordType.workoutPhoto.rawValue, predicate: predicate)
        
        // Sort by timestamp
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        // Perform the query
        privateDB.perform(query, inZoneWith: nil) { [weak self] (records, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let records = records, !records.isEmpty else {
                    // No error, but no records found
                    completion(.success([]))
                    return
                }
                
                // Convert all records to images
                var images: [UIImage] = []
                for record in records {
                    guard let asset = record["photo"] as? CKAsset, 
                          let fileURL = asset.fileURL else {
                        continue
                    }
                    
                    do {
                        let data = try Data(contentsOf: fileURL)
                        if let image = UIImage(data: data) {
                            images.append(image)
                        }
                    } catch {
                        print("Error loading image from record: \(error)")
                    }
                }
                
                completion(.success(images))
            }
        }
    }
    
    // Helper method to temporarily save image data to disk
    private func saveImageTemporarily(data: Data) -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            // If writing fails, try using NSTemporaryDirectory() as fallback
            let fallbackURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            try? data.write(to: fallbackURL)
            return fallbackURL
        }
    }
    
    // Add this method to check and create record types if needed
    private func checkAndCreateRecordTypeIfNeeded(recordType: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to create schema for \(recordType)")
        
        // First, try to fetch a record of this type to see if it exists
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: false))
        
        privateDB.perform(query, inZoneWith: nil) { (_, error) in
            if let error = error as? CKError, error.code == .unknownItem {
                // Record type doesn't exist, create it
                self.createRecordType(recordType: recordType, completion: completion)
            } else {
                // Record type exists or there was a different error
                completion(error == nil)
            }
        }
    }
    
    private func createRecordType(recordType: String, completion: @escaping (Bool) -> Void) {
        print("Creating record type: \(recordType)")
        
        // Create a dummy record with the needed fields
        let dummyRecord = CKRecord(recordType: recordType)
        dummyRecord["photo"] = CKAsset(fileURL: FileManager.default.temporaryDirectory) // Will fail but creates field
        dummyRecord["isInitial"] = true
        dummyRecord["day"] = 0
        dummyRecord["timestamp"] = Date()
        
        // Save the record to create the schema
        privateDB.save(dummyRecord) { (_, error) in
            if let error = error {
                print("Failed to create schema: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully created schema")
                completion(true)
            }
        }
    }
} 
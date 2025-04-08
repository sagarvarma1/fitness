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
    
    // Save a photo to CloudKit using direct record ID
    func savePhoto(image: UIImage, isInitial: Bool, day: Int = 0, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        isLoading = true
        
        // Convert UIImage to compressed data
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            let error = NSError(domain: "CloudKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            completion(.failure(error))
            isLoading = false
            return
        }
        
        // Create a record ID with a predictable name pattern
        let recordName = isInitial ? "initial_photo" : "day_\(day)_photo"
        let recordID = CKRecord.ID(recordName: recordName)
        
        // Create a new record with the specific ID
        let record = CKRecord(recordType: RecordType.workoutPhoto.rawValue, recordID: recordID)
        
        // Create an asset from the image data
        let imageAsset = CKAsset(fileURL: saveImageTemporarily(data: imageData))
        
        // Set record values - simpler now, we mainly need the photo
        record["photo"] = imageAsset
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
    
    // Fetch the initial photo from CloudKit using direct record ID
    func fetchInitialPhoto(completion: @escaping (Result<UIImage?, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: "initial_photo")
        
        privateDB.fetch(withRecordID: recordID) { [weak self] (record, error) in
            DispatchQueue.main.async {
                if let error = error as? CKError {
                    if error.code == .unknownItem {
                        // Record doesn't exist yet, not an error
                        completion(.success(nil))
                    } else {
                        self?.error = error
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let record = record, let asset = record["photo"] as? CKAsset, let fileURL = asset.fileURL else {
                    completion(.success(nil))
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
    
    // Fetch photo for a specific day
    func fetchPhotoForDay(day: Int, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: "day_\(day)_photo")
        
        privateDB.fetch(withRecordID: recordID) { [weak self] (record, error) in
            DispatchQueue.main.async {
                if let error = error as? CKError {
                    if error.code == .unknownItem {
                        // Record doesn't exist yet, not an error
                        completion(.success(nil))
                    } else {
                        self?.error = error
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let record = record, let asset = record["photo"] as? CKAsset, let fileURL = asset.fileURL else {
                    completion(.success(nil))
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
} 
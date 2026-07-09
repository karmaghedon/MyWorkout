import Foundation

/// A centralized exercise lookup that searches both built-in SeedData exercises
/// and exercises found in user templates, ensuring analytics and recovery log 
/// can find user-created exercises.
struct ExerciseRegistry {
    private init() {}
    
    // MARK: - Cache
    
    private static var cachedUserExercises: [Exercise]?
    private static var cachedTimestamp: Date?
    private static let cachedLifetime: TimeInterval = 60 // 1 min
    private static let cacheLock = NSLock()
    
    ///  Invalidate the exercise cache. Call this after modifying templates.
    static func invalidateCache() {
        cacheLock.lock()
        defer {cacheLock.unlock() }
        cachedUserExercises = nil
        cachedTimestamp = nil
    }
    
    // MARK: - Public API
    
    /// Find the exercise definition matching a completed exercise log entry.
    /// Checks SeedData first, then falls back to searching templates.
    static func find(for completed: CompletedExercise) -> Exercise? {
        // First check built-in exercises (fast path)
        if let match = SeedData.exercises.first(where: {
            if let completedID = completed.exerciseID {
                return $0.id == completedID
            }
            return $0.name == completed.exerciseName
        }) {
            return match
        }
        
        // Fall back to exercises from user templates
        return userExercises.first {
            if let completedID = completed.exerciseID {
                return $0.id == completedID
            }
            return $0.name == completed.exerciseName
        }
    }
    
    /// Find an exercise by ID or name.
    static func find(id: UUID?, name: String) -> Exercise? {
        if let match = SeedData.exercises.first(where: {
            if let id { return $0.id == id }
            return $0.name == name
        }) {
            return match
        }
        
        return userExercises.first {
            if let id { return $0.id == id }
            return $0.name == name
        }
    }
    
    // MARK: - Private Helpers
    
    /// Exercises defined only in user templates (not in SeedData).
    /// Cached for 1 minute to avoid repeated disk read.
    private static var userExercises: [Exercise] {
        cacheLock.lock()
        defer {cacheLock.unlock()}
        
        // Return cached version if still valid
        if let cached = cachedUserExercises,
           let timestamp = cachedTimestamp,
           Date().timeIntervalSince(timestamp) < cachedLifetime {
            return cached
        }
        
        // Load form disk
        let seedIDs = Set(SeedData.exercises.map(\.id))
        let seedNames = Set(SeedData.exercises.map(\.name))
        
        guard let url = templateFileURL,
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) else {
            cachedUserExercises = []
            cachedTimestamp = Date()
            return []
        }
        
        let exercise = templates
            .flatMap(\.exercises)
            .filter { !seedIDs.contains($0.id) && !seedNames.contains($0.name) }
        
        cachedUserExercises = exercise
        cachedTimestamp = Date()
        return exercise
    }
    
    private static var templateFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("MyWorkout/workout_templates.json") }
}

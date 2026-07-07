import Foundation

struct ProgressionRule: Codable {
    let minReps: Int
    let maxReps: Int
    let increaseAmount: Double
    let deloadAmount: Double
    let stallLimit: Int
    
    enum ConfigKeys: String, CodingKey {
        case minReps, maxReps, increaseAmount, deloadAmount, stallLimit
    }
    
    init(
        minReps: Int,
        maxReps: Int,
        increaseAmount: Double,
        deloadAmount: Double,
        stallLimit: Int
    ) {
        self.minReps = minReps
        self.maxReps = maxReps
        self.increaseAmount = increaseAmount
        self.deloadAmount = deloadAmount
        self.stallLimit = stallLimit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        minReps = try container.decode(Int.self, forKey: .minReps)
        maxReps = try container.decode(Int.self, forKey: .maxReps)
        stallLimit = try container.decode(Int.self, forKey: .stallLimit)
        
        // Support both Int and Double for amounts (migration compatibility)
        if let doubleIncrease = try? container.decode(Double.self, forKey: .increaseAmount) {
            increaseAmount = doubleIncrease
        } else if let intIncrease = try? container.decode(Int.self, forKey: .increaseAmount) {
            increaseAmount = Double(intIncrease)
        } else {
            increaseAmount = 5.0
        }

        if let doubleDeload = try? container.decode(Double.self, forKey: .deloadAmount) {
            deloadAmount = doubleDeload
        } else if let intDeload = try? container.decode(Int.self, forKey: .deloadAmount) {
            deloadAmount = Double(intDeload)
        } else {
            deloadAmount = 10.0
        }
        
    }
}

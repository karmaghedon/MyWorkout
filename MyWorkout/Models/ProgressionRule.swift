import Foundation

struct ProgressionRule: Codable {
    let minReps: Int
    let maxReps: Int
    let increaseAmount: Int
    let deloadAmount: Int
    let stallLimit: Int
}

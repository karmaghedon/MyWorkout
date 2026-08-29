import Foundation

struct WarmupSet: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var reps: Int

    init(id: UUID = UUID(), weight: Double, reps: Int) {
        self.id = id
        self.weight = weight
        self.reps = reps
    }
}

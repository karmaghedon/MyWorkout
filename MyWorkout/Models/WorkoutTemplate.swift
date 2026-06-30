import Foundation

struct WorkoutTemplate: Identifiable, Codable {
    var id = UUID()
    var name: String
    var exercises: [Exercise]
}

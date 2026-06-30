import Foundation

struct Workout: Identifiable, Codable {
    var id = UUID()
    let name: String
    let exercises: [Exercise]
}

import Foundation

struct PlateLoading: Identifiable {
    let id = UUID()
    let totalWeight: Int
    let platesPerSide: [Double]

    var displayText: String {
        if platesPerSide.isEmpty {
            return "empty bar"
        }

        return platesPerSide
            .map { plate in
                plate.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(plate))"
                : "\(plate)"
            }
            .joined(separator: " + ")
    }
}

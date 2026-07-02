import Foundation

struct PlateLoading: Identifiable {
    let id = UUID()
    let totalWeight: Int
    let platesPerSide: [Double]

    func displayText(in unit: UnitSystem) -> String {
        if platesPerSide.isEmpty {
            return "empty bar"
        }

        return platesPerSide
            .map { plateLb in
                let displayed = WeightConversion.fromPounds(plateLb, to: unit)
                return format(displayed)
            }
            .joined(separator: " + ")
    }

    private func format(_ value: Double) -> String {
        let roundedToHalf = (value * 2).rounded() / 2

        if roundedToHalf.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(roundedToHalf))"
        }

        return "\(roundedToHalf)"
    }
}

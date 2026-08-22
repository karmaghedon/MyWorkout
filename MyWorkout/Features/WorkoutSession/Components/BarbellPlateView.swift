import SwiftUI

/// A compact schematic of one side of a loaded barbell — a sleeve nub
/// followed by each plate as a block sized roughly to its relative weight,
/// with the weight printed on the plate. Replaces the plain-text plate
/// breakdown (e.g. "45 + 35 + 25 + 5 lb/side") which becomes unreadable at
/// heavier loads with many plates; a graphic reads as a shape at a glance
/// regardless of how many plates are stacked.
struct BarbellPlateView: View {
    let loading: PlateLoading
    let unitSystem: UnitSystem

    private static let referenceWeight: Double = 45
    private static let minPlateHeight: CGFloat = 16
    private static let maxPlateHeight: CGFloat = 34
    private static let plateWidth: CGFloat = 10

    var body: some View {
        if loading.platesPerSide.isEmpty {
            Text("empty bar")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
        } else {
            HStack(spacing: 1) {
                sleeveNub

                // Heaviest plates load closest to the sleeve, same as a
                // real bar — `platesPerSide` is already heaviest-first.
                ForEach(Array(loading.platesPerSide.enumerated()), id: \.offset) { _, plateWeight in
                    plateBlock(for: plateWeight)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "\(loading.displayText(in: unitSystem)) \(unitSystem.rawValue) per side"
            )
        }
    }

    private var sleeveNub: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(AppTheme.secondaryText.opacity(0.35))
            .frame(width: 6, height: Self.minPlateHeight)
    }

    private func plateBlock(for weightPounds: Double) -> some View {
        let displayed = WeightConversion.fromPounds(weightPounds, to: unitSystem)

        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(AppTheme.accent.opacity(opacity(for: weightPounds)))
            .frame(width: Self.plateWidth, height: height(for: weightPounds))
            .overlay {
                Text(formatPlate(displayed))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
            }
    }

    private func height(for weightPounds: Double) -> CGFloat {
        let ratio = min(1, weightPounds / Self.referenceWeight)
        return Self.minPlateHeight + (Self.maxPlateHeight - Self.minPlateHeight) * ratio
    }

    private func opacity(for weightPounds: Double) -> Double {
        let ratio = min(1, weightPounds / Self.referenceWeight)
        return 0.45 + 0.55 * ratio
    }

    private func formatPlate(_ value: Double) -> String {
        let roundedToHalf = (value * 2).rounded() / 2

        if roundedToHalf.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(roundedToHalf))"
        }

        return "\(roundedToHalf)"
    }
}

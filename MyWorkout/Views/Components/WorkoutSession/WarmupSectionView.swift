import SwiftUI

struct WarmupSectionView: View {
    let warmups: [WarmupSet]
    let usesBarbell: Bool
    let equipmentInventory: EquipmentInventory
    let displayWeight: (Int) -> Int
    let weightUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("WARM-UP")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(warmups) { warmup in
                HStack {
                    Text("\(displayWeight(warmup.weight)) \(weightUnit) × \(warmup.reps)")
                        .font(AppTheme.Typography.caption)

                    if usesBarbell {
                        Spacer()

                        let loading = PlateCalculator.loading(
                            for: warmup.weight,
                            inventory: equipmentInventory
                        )

                        Text("\(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}

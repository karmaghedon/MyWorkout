import SwiftUI

struct InventoryItemRow: View {
    @Binding var weight: Double
    @Binding var quantity: Int

    let unit: String
    let itemLabel: String
    let onDelete: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            weightField

            Text(unit)
                .foregroundStyle(.secondary)

            Stepper(value: $quantity, in: 0...20) {
                Text("Qty: \(quantity)")
            }
            .fixedSize()
            .accessibilityLabel("\(itemLabel) quantity")
            .accessibilityValue("\(quantity)")

            Spacer(minLength: 0)

            deleteButton
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.md) {
                weightField

                Text(unit)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                deleteButton
            }

            Stepper(value: $quantity, in: 0...20) {
                Text("Qty: \(quantity)")
            }
            .accessibilityLabel("\(itemLabel) quantity")
            .accessibilityValue("\(quantity)")
        }
    }

    private var weightField: some View {
        TextField("Weight", value: $weight, format: .number)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
            .accessibilityLabel("\(itemLabel) weight in \(unit)")
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete \(itemLabel.lowercased()), \(weight, specifier: "%g") \(unit)")
    }
}

import SwiftUI

struct InventoryAddItemRow: View {
    let title: String
    let unit: String

    @Binding var weight: String
    @Binding var quantity: String

    let onAdd: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            textField("Weight", text: $weight)

            Text(unit)
                .foregroundStyle(.secondary)

            textField("Qty", text: $quantity)

            Spacer(minLength: 0)

            addButton
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                textField("Weight", text: $weight)

                Text(unit)
                    .foregroundStyle(.secondary)

                textField("Qty", text: $quantity)
            }

            addButton
        }
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Label(title, systemImage: "plus.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
    }
}

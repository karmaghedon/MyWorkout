import SwiftUI

struct BarbellInventorySection: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var showResetConfirmation = false

    private var unit: String {
        settingsStore.settings.weightUnitLabel
    }

    var body: some View {
        InventorySectionCard(title: "Barbell") {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Text("Barbell weight")

                    barbellWeightField

                    Text(unit)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Barbell weight")

                    HStack(spacing: AppTheme.Spacing.md) {
                        barbellWeightField

                        Text(unit)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }
                }
            }

            Button("Reset Inventory to Default") {
                showResetConfirmation = true
            }
            .foregroundStyle(.red)
            .accessibilityHint("Replaces all plates and dumbbells with the default set. This cannot be undone.")
            .confirmationDialog(
                "Reset Inventory",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to Default", role: .destructive) {
                    equipmentStore.resetToDefault(
                        unit: settingsStore.settings.unitSystem
                    )
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace all plates and dumbbells with the default set. This cannot be undone.")
            }
        }
    }

    private var barbellWeightField: some View {
        TextField(
            "Weight",
            value: $equipmentStore.inventory.barbellWeight,
            format: .number
        )
        .textFieldStyle(.roundedBorder)
        .keyboardType(.decimalPad)
        .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
        .accessibilityLabel("Barbell weight in \(unit)")
        .onChange(of: equipmentStore.inventory.barbellWeight) { _ in
            equipmentStore.save()
        }
    }
}

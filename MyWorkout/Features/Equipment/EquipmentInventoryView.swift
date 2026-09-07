import SwiftUI

struct EquipmentInventoryView: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                BarbellInventorySection()
                PlatesInventorySection()
                DumbbellsInventorySection()
            }
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .dismissKeyboardOnTap()
        .navigationTitle("Equipment Inventory")
        .onAppear {
            syncInventoryUnitIfNeeded()
        }
    }

    private func syncInventoryUnitIfNeeded() {
        guard equipmentStore.inventory.unitSystem != settingsStore.settings.unitSystem else {
            return
        }

        equipmentStore.convertInventory(
            to: settingsStore.settings.unitSystem
        )
    }
}

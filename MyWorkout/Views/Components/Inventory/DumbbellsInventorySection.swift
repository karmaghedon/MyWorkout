import SwiftUI

struct DumbbellsInventorySection: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var newDumbbellWeight = ""
    @State private var newDumbbellQuantity = ""

    private var unit: String {
        settingsStore.settings.weightUnitLabel
    }

    var body: some View {
        InventorySectionCard(title: "Dumbbells") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.dumbbells) { dumbbell in
                    InventoryItemRow(
                        weight: bindingForWeight(id: dumbbell.id),
                        quantity: bindingForQuantity(id: dumbbell.id),
                        unit: unit,
                        itemLabel: "Dumbbell",
                        onDelete: {
                            equipmentStore.deleteDumbbell(id: dumbbell.id)
                        }
                    )
                }

                InventoryAddItemRow(
                    title: "Add Dumbbell",
                    unit: unit,
                    weight: $newDumbbellWeight,
                    quantity: $newDumbbellQuantity,
                    onAdd: addDumbbell
                )
            }
        }
    }

    private func bindingForWeight(id: UUID) -> Binding<Double> {
        Binding(
            get: {
                equipmentStore.inventory.dumbbells.first { $0.id == id }?.weight ?? 0
            },
            set: { newValue in
                if let index = equipmentStore.inventory.dumbbells.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.dumbbells[index].weight = newValue
                    equipmentStore.save()
                }
            }
        )
    }

    private func bindingForQuantity(id: UUID) -> Binding<Int> {
        Binding(
            get: {
                equipmentStore.inventory.dumbbells.first { $0.id == id }?.quantity ?? 0
            },
            set: { newValue in
                if let index = equipmentStore.inventory.dumbbells.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.dumbbells[index].quantity = newValue
                    equipmentStore.save()
                }
            }
        )
    }

    private func addDumbbell() {
        guard let weight = Double(newDumbbellWeight),
              let quantity = Int(newDumbbellQuantity),
              quantity > 0 else {
            return
        }

        equipmentStore.addDumbbell(weight: weight, quantity: quantity)

        newDumbbellWeight = ""
        newDumbbellQuantity = ""
    }
}

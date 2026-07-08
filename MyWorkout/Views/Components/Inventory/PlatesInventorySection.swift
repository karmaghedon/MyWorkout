import SwiftUI

struct PlatesInventorySection: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var newPlateWeight = ""
    @State private var newPlateQuantity = ""

    private var unit: String {
        settingsStore.settings.weightUnitLabel
    }

    var body: some View {
        InventorySectionCard(title: "Plates") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.plates) { plate in
                    InventoryItemRow(
                        weight: bindingForWeight(id: plate.id),
                        quantity: bindingForQuantity(id: plate.id),
                        unit: unit,
                        itemLabel: "Plate",
                        onDelete: {
                            equipmentStore.deletePlate(id: plate.id)
                        }
                    )
                }

                InventoryAddItemRow(
                    title: "Add Plate",
                    unit: unit,
                    weight: $newPlateWeight,
                    quantity: $newPlateQuantity,
                    onAdd: addPlate
                )
            }
        }
    }

    private func bindingForWeight(id: UUID) -> Binding<Double> {
        Binding(
            get: {
                equipmentStore.inventory.plates.first { $0.id == id }?.weight ?? 0
            },
            set: { newValue in
                if let index = equipmentStore.inventory.plates.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.plates[index].weight = newValue
                    equipmentStore.save()
                }
            }
        )
    }

    private func bindingForQuantity(id: UUID) -> Binding<Int> {
        Binding(
            get: {
                equipmentStore.inventory.plates.first { $0.id == id }?.quantity ?? 0
            },
            set: { newValue in
                if let index = equipmentStore.inventory.plates.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.plates[index].quantity = newValue
                    equipmentStore.save()
                }
            }
        )
    }

    private func addPlate() {
        guard let weight = Double(newPlateWeight),
              let quantity = Int(newPlateQuantity),
              quantity > 0 else {
            return
        }

        equipmentStore.addPlate(weight: weight, quantity: quantity)

        newPlateWeight = ""
        newPlateQuantity = ""
    }
}

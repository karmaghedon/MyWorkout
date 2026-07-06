import SwiftUI

struct EquipmentInventoryView: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var newPlateWeight = ""
    @State private var newPlateQuantity = ""
    @State private var newDumbbellWeight = ""
    @State private var newDumbbellQuantity = ""

    private var unit: String {
        settingsStore.settings.weightUnitLabel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                barbellSection
                platesSection
                dumbbellsSection
            }
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle("Equipment Inventory")
        .onAppear {
            syncInventoryUnitIfNeeded()
        }
    }

    private var barbellSection: some View {
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
                equipmentStore.resetToDefault(
                    unit: settingsStore.settings.unitSystem
                )
            }
            .foregroundStyle(.red)
        }
    }

    private var platesSection: some View {
        InventorySectionCard(title: "Plates") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.plates) { plate in
                    InventoryItemRow(
                        weight: bindingForPlateWeight(id: plate.id),
                        quantity: bindingForPlateQuantity(id: plate.id),
                        unit: unit,
                        onDelete: {
                            deletePlate(id: plate.id)
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

    private var dumbbellsSection: some View {
        InventorySectionCard(title: "Dumbbells") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.dumbbells) { dumbbell in
                    InventoryItemRow(
                        weight: bindingForDumbbellWeight(id: dumbbell.id),
                        quantity: bindingForDumbbellQuantity(id: dumbbell.id),
                        unit: unit,
                        onDelete: {
                            deleteDumbbell(id: dumbbell.id)
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

    private var barbellWeightField: some View {
        TextField(
            "Weight",
            value: $equipmentStore.inventory.barbellWeight,
            format: .number
        )
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
        .keyboardType(.decimalPad)
        #endif
        .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
        .onChange(of: equipmentStore.inventory.barbellWeight) { _ in
            equipmentStore.save()
        }
    }

    private func syncInventoryUnitIfNeeded() {
        guard equipmentStore.inventory.unitSystem != settingsStore.settings.unitSystem else {
            return
        }

        equipmentStore.convertInventory(
            to: settingsStore.settings.unitSystem,
            from: equipmentStore.inventory.unitSystem
        )
    }

    private func bindingForPlateWeight(id: UUID) -> Binding<Double> {
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

    private func bindingForPlateQuantity(id: UUID) -> Binding<Int> {
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

    private func bindingForDumbbellWeight(id: UUID) -> Binding<Double> {
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

    private func bindingForDumbbellQuantity(id: UUID) -> Binding<Int> {
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

    private func deletePlate(id: UUID) {
        equipmentStore.inventory.plates.removeAll { $0.id == id }
        equipmentStore.save()
    }

    private func deleteDumbbell(id: UUID) {
        equipmentStore.inventory.dumbbells.removeAll { $0.id == id }
        equipmentStore.save()
    }
}

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
            if equipmentStore.inventory.unitSystem != settingsStore.settings.unitSystem {
                equipmentStore.convertInventory(
                    to: settingsStore.settings.unitSystem,
                    from: equipmentStore.inventory.unitSystem
                )
            }
        }
    }

    private var inventoryUnitSection: some View {
        sectionCard(title: "Inventory Units") {
            Picker("Inventory Unit", selection: $equipmentStore.inventory.unitSystem) {
                ForEach(UnitSystem.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: equipmentStore.inventory.unitSystem) { _ in
                equipmentStore.save()
            }
        }
    }

    private var barbellSection: some View {
        sectionCard(title: "Barbell") {
            HStack {
                Text("Barbell weight")
                    .frame(width: 160, alignment: .leading)

                TextField("Weight", value: $equipmentStore.inventory.barbellWeight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Text(unit)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .onChange(of: equipmentStore.inventory.barbellWeight) { _ in
                equipmentStore.save()
            }
            Button("Reset Inventory to Default") {
                equipmentStore.resetToDefault(unit: settingsStore.settings.unitSystem)
            }
            .foregroundStyle(.red)
        }
    }

    private var platesSection: some View {
        sectionCard(title: "Plates") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.plates) { plate in
                    inventoryRow(
                        weight: bindingForPlateWeight(id: plate.id),
                        quantity: bindingForPlateQuantity(id: plate.id),
                        deleteAction: {
                            deletePlate(id: plate.id)
                        }
                    )
                }

                addRow(
                    title: "Add Plate",
                    weightText: $newPlateWeight,
                    quantityText: $newPlateQuantity,
                    placeholder: "Plate weight",
                    action: addPlate
                )
            }
        }
    }

    private var dumbbellsSection: some View {
        sectionCard(title: "Dumbbells") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(equipmentStore.inventory.dumbbells) { dumbbell in
                    inventoryRow(
                        weight: bindingForDumbbellWeight(id: dumbbell.id),
                        quantity: bindingForDumbbellQuantity(id: dumbbell.id),
                        deleteAction: {
                            deleteDumbbell(id: dumbbell.id)
                        }
                    )
                }

                addRow(
                    title: "Add Dumbbell",
                    weightText: $newDumbbellWeight,
                    quantityText: $newDumbbellQuantity,
                    placeholder: "Dumbbell weight",
                    action: addDumbbell
                )
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title)
                .font(AppTheme.Typography.sectionTitle)

            content()
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func inventoryRow(
        weight: Binding<Double>,
        quantity: Binding<Int>,
        deleteAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text("Weight")
                .frame(width: 80, alignment: .leading)

            TextField("Weight", value: weight, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)

            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)

            Stepper(value: quantity, in: 0...20) {
                Text("Qty: \(quantity.wrappedValue)")
                    .frame(width: 80, alignment: .leading)
            }
            .frame(width: 160)

            Button("Delete") {
                deleteAction()
            }
            .foregroundStyle(.red)

            Spacer()
        }
    }

    private func addRow(
        title: String,
        weightText: Binding<String>,
        quantityText: Binding<String>,
        placeholder: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(title)
                .frame(width: 100, alignment: .leading)

            TextField(placeholder, text: weightText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)

            Text(unit)
                .foregroundStyle(.secondary)

            TextField("Qty", text: quantityText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)

            Button("Add") {
                action()
            }
            .disabled(!canAdd(weightText: weightText.wrappedValue, quantityText: quantityText.wrappedValue))

            Spacer()
        }
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

    private func canAdd(weightText: String, quantityText: String) -> Bool {
        guard let quantity = Int(quantityText), quantity > 0 else { return false }
        return Double(weightText) != nil
    }

    private func addPlate() {
        guard let weight = Double(newPlateWeight),
              let quantity = Int(newPlateQuantity),
              quantity > 0 else { return }

        equipmentStore.addPlate(weight: weight, quantity: quantity)
        newPlateWeight = ""
        newPlateQuantity = ""
    }

    private func addDumbbell() {
        guard let weight = Double(newDumbbellWeight),
              let quantity = Int(newDumbbellQuantity),
              quantity > 0 else { return }

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

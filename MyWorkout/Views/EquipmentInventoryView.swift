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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Text("Barbell weight")

                    weightField($equipmentStore.inventory.barbellWeight)

                    Text(unit)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Barbell weight")

                    HStack(spacing: AppTheme.Spacing.md) {
                        weightField($equipmentStore.inventory.barbellWeight)

                        Text(unit)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }
                }
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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Spacing.md) {
                weightField(weight)

                Text(unit)
                    .foregroundStyle(.secondary)

                Stepper(value: quantity, in: 0...20) {
                    Text("Qty: \(quantity.wrappedValue)")
                }
                .fixedSize()

                Spacer(minLength: 0)

                deleteButton(action: deleteAction)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.md) {
                    weightField(weight)

                    Text(unit)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    deleteButton(action: deleteAction)
                }

                Stepper(value: quantity, in: 0...20) {
                    Text("Qty: \(quantity.wrappedValue)")
                }
            }
        }
    }

    private func weightField(_ weight: Binding<Double>) -> some View {
        TextField("Weight", value: weight, format: .number)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
            .frame(minWidth: 60, idealWidth: 80, maxWidth: 100)
    }

    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
    }

    private func addRow(
        title: String,
        weightText: Binding<String>,
        quantityText: Binding<String>,
        placeholder: String,
        action: @escaping () -> Void
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Spacing.md) {
                addRowFields(weightText: weightText, quantityText: quantityText, placeholder: placeholder)

                Button("Add", action: action)
                    .disabled(!canAdd(weightText: weightText.wrappedValue, quantityText: quantityText.wrappedValue))
                    .accessibilityLabel(title)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                addRowFields(weightText: weightText, quantityText: quantityText, placeholder: placeholder)

                Button("Add", action: action)
                    .disabled(!canAdd(weightText: weightText.wrappedValue, quantityText: quantityText.wrappedValue))
                    .accessibilityLabel(title)
            }
        }
    }

    private func addRowFields(
        weightText: Binding<String>,
        quantityText: Binding<String>,
        placeholder: String
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            TextField(placeholder, text: weightText)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .frame(minWidth: 90, idealWidth: 120, maxWidth: 140)

            Text(unit)
                .foregroundStyle(.secondary)

            TextField("Qty", text: quantityText)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .frame(minWidth: 44, idealWidth: 60, maxWidth: 70)
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

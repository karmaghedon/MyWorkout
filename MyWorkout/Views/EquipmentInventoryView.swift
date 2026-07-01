import SwiftUI

struct EquipmentInventoryView: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore

    @State private var newPlateWeight = ""
    @State private var newPlateQuantity = ""
    @State private var newDumbbellWeight = ""
    @State private var newDumbbellQuantity = ""

    var body: some View {
        Form {
            Section {
                barbellRow
            } header: {
                Text("Barbell")
            }

            Section {
                ForEach(equipmentStore.inventory.plates) { plate in
                    weightRow(
                        weight: bindingForPlateWeight(id: plate.id),
                        quantity: bindingForPlateQuantity(id: plate.id)
                    )
                }
                .onDelete(perform: deletePlates)

                addRow(
                    weightText: $newPlateWeight,
                    quantityText: $newPlateQuantity,
                    placeholder: "New plate weight",
                    accessibilityLabel: "Add plate",
                    action: addPlate
                )
            } header: {
                Text("Plates (per plate, not per pair)")
            }

            Section {
                ForEach(equipmentStore.inventory.dumbbells) { dumbbell in
                    weightRow(
                        weight: bindingForDumbbellWeight(id: dumbbell.id),
                        quantity: bindingForDumbbellQuantity(id: dumbbell.id)
                    )
                }
                .onDelete(perform: deleteDumbbells)

                addRow(
                    weightText: $newDumbbellWeight,
                    quantityText: $newDumbbellQuantity,
                    placeholder: "New dumbbell weight",
                    accessibilityLabel: "Add dumbbell",
                    action: addDumbbell
                )
            } header: {
                Text("Dumbbells")
            }
        }
        .navigationTitle("Equipment Inventory")
        // NOTE: Using the single-parameter onChange (macOS 11+/iOS 14+) instead of
        // the newer two-parameter { old, new in ... } form, which requires macOS 14+.
        // None of these handlers need the old/new values — they just trigger a save.
        .onChange(of: equipmentStore.inventory.barbellWeight) { _ in
            equipmentStore.save()
        }
        .onChange(of: equipmentStore.inventory.plates) { _ in
            equipmentStore.save()
        }
        .onChange(of: equipmentStore.inventory.dumbbells) { _ in
            equipmentStore.save()
        }
    }

    // MARK: - Rows

    private var barbellRow: some View {
        HStack {
            Text("Barbell weight")

            Spacer()

            TextField("45", value: $equipmentStore.inventory.barbellWeight, format: .number)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 60)

            Text("lb")
                .foregroundStyle(.secondary)
        }
    }

    /// A single existing plate/dumbbell entry. Changes save automatically
    /// via onChange on the parent — no per-row Save button needed.
    private func weightRow(weight: Binding<Double>, quantity: Binding<Int>) -> some View {
        HStack {
            TextField("Weight", value: weight, format: .number)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .frame(minWidth: 44, maxWidth: 70)

            Text("lb")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: AppTheme.Spacing.sm)

            Stepper(value: quantity, in: 0...20) {
                Text("Qty: \(quantity.wrappedValue)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addRow(
        weightText: Binding<String>,
        quantityText: Binding<String>,
        placeholder: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            TextField(placeholder, text: weightText)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif

            TextField("Qty", text: quantityText)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .frame(width: 50)

            Button(action: action) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
            .disabled(!canAdd(weightText: weightText.wrappedValue, quantityText: quantityText.wrappedValue))
            .accessibilityLabel(accessibilityLabel)
        }
    }

    // MARK: - Bindings
    //
    // Building fresh Bindings by ID (instead of $equipmentStore.inventory.plates[index])
    // keeps rows stable across inserts/deletes without index math scattered in the view.

    private func bindingForPlateWeight(id: UUID) -> Binding<Double> {
        Binding(
            get: { equipmentStore.inventory.plates.first { $0.id == id }?.weight ?? 0 },
            set: { newValue in
                if let index = equipmentStore.inventory.plates.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.plates[index].weight = newValue
                }
            }
        )
    }

    private func bindingForPlateQuantity(id: UUID) -> Binding<Int> {
        Binding(
            get: { equipmentStore.inventory.plates.first { $0.id == id }?.quantity ?? 0 },
            set: { newValue in
                if let index = equipmentStore.inventory.plates.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.plates[index].quantity = newValue
                }
            }
        )
    }

    private func bindingForDumbbellWeight(id: UUID) -> Binding<Double> {
        Binding(
            get: { equipmentStore.inventory.dumbbells.first { $0.id == id }?.weight ?? 0 },
            set: { newValue in
                if let index = equipmentStore.inventory.dumbbells.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.dumbbells[index].weight = newValue
                }
            }
        )
    }

    private func bindingForDumbbellQuantity(id: UUID) -> Binding<Int> {
        Binding(
            get: { equipmentStore.inventory.dumbbells.first { $0.id == id }?.quantity ?? 0 },
            set: { newValue in
                if let index = equipmentStore.inventory.dumbbells.firstIndex(where: { $0.id == id }) {
                    equipmentStore.inventory.dumbbells[index].quantity = newValue
                }
            }
        )
    }

    // MARK: - Actions

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

    private func deletePlates(at offsets: IndexSet) {
        equipmentStore.deletePlates(at: offsets)
    }

    private func deleteDumbbells(at offsets: IndexSet) {
        equipmentStore.deleteDumbbells(at: offsets)
    }
}

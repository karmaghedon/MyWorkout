import SwiftUI

struct EquipmentInventoryView: View {
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore

    @State private var newPlateWeight = ""
    @State private var newPlateQuantity = ""
    @State private var newDumbbellWeight = ""
    @State private var newDumbbellQuantity = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                barbellSection
                platesSection
                dumbbellsSection
            }
            .padding()
        }
        .navigationTitle("Equipment Inventory")
    }

    private var barbellSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Barbell")
                .font(.title3)
                .bold()

            HStack {
                Text("Barbell weight")
                    .frame(width: 140, alignment: .leading)

                TextField("45", value: $equipmentStore.inventory.barbellWeight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Text("lb")

                Button("Save") {
                    equipmentStore.save()
                }
            }
        }
    }

    private var platesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plates")
                .font(.title3)
                .bold()

            ForEach($equipmentStore.inventory.plates) { $plate in
                HStack {
                    TextField("Weight", value: $plate.weight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    Text("lb")

                    Stepper("Qty: \(plate.quantity)", value: $plate.quantity, in: 0...20)
                        .frame(width: 140)

                    Button("Save") {
                        equipmentStore.save()
                    }

                    Button("Delete") {
                        deletePlate(id: plate.id)
                    }
                }
            }

            HStack {
                TextField("New plate weight", text: $newPlateWeight)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)

                TextField("Qty", text: $newPlateQuantity)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)

                Button("Add Plate") {
                    addPlate()
                }
            }
        }
    }

    private var dumbbellsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dumbbells")
                .font(.title3)
                .bold()

            ForEach($equipmentStore.inventory.dumbbells) { $dumbbell in
                HStack {
                    TextField("Weight", value: $dumbbell.weight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    Text("lb")

                    Stepper("Qty: \(dumbbell.quantity)", value: $dumbbell.quantity, in: 0...20)
                        .frame(width: 140)

                    Button("Save") {
                        equipmentStore.save()
                    }

                    Button("Delete") {
                        deleteDumbbell(id: dumbbell.id)
                    }
                }
            }

            HStack {
                TextField("New dumbbell weight", text: $newDumbbellWeight)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 170)

                TextField("Qty", text: $newDumbbellQuantity)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)

                Button("Add Dumbbell") {
                    addDumbbell()
                }
            }
        }
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

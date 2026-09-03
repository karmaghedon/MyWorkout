import Foundation

@MainActor
final class EquipmentInventoryStore: ObservableObject {
    @Published var inventory: EquipmentInventory

    @Published private(set) var persistenceError: StoreError?

    private let fileURL: URL

    /// The pre-file-based-persistence key — see the equivalent comment
    /// on `UserSettingsStore` for why this moved off `UserDefaults`
    /// (`synchronize()` doesn't actually force a disk flush on modern
    /// iOS, confirmed by real data loss on device). Kept only as a
    /// one-time migration source for whatever's already stored there.
    private let legacyUserDefaults: UserDefaults
    private let legacyPersistenceKey: String

    init(
        fileURL: URL = EquipmentInventoryStore.defaultFileURL(),
        legacyUserDefaults: UserDefaults = .standard,
        legacyPersistenceKey: String = "equipment_inventory"
    ) {
        self.fileURL = fileURL
        self.legacyUserDefaults = legacyUserDefaults
        self.legacyPersistenceKey = legacyPersistenceKey

        if let data = Self.readData(
            fileURL: fileURL,
            legacyUserDefaults: legacyUserDefaults,
            legacyPersistenceKey: legacyPersistenceKey
        ) {
            do {
                inventory = try JSONDecoder().decode(
                    EquipmentInventory.self,
                    from: data.payload
                )

                clearPersistenceError(
                    for: .loading
                )

                if data.isFromLegacyLocation {
                    save()
                }
            } catch {
                print(
                    "Failed to load equipment inventory: \(error)"
                )

                inventory =
                    EquipmentInventory.defaultInventory

                setPersistenceError(
                    operation: .loading,
                    message:
                        "Couldn't load equipment inventory. "
                        + "Defaults were restored."
                )

                save()
            }
        } else {
            inventory =
                EquipmentInventory.defaultInventory

            save()
        }
    }

    /// Reads from the current file location first; falls back to the
    /// legacy `UserDefaults` key only if the file doesn't exist yet
    /// (the first launch since the persistence backend changed), so a
    /// real inventory from before this change still gets picked up
    /// exactly once instead of silently resetting to defaults.
    private static func readData(
        fileURL: URL,
        legacyUserDefaults: UserDefaults,
        legacyPersistenceKey: String
    ) -> (payload: Data, isFromLegacyLocation: Bool)? {
        if let fileData = try? Data(contentsOf: fileURL) {
            return (fileData, false)
        }

        guard let legacyData = legacyUserDefaults.data(forKey: legacyPersistenceKey) else {
            return nil
        }

        return (legacyData, true)
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation
                == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Persistence

    func save() {
        do {
            try ensureDirectoryExists()

            let data = try JSONEncoder().encode(
                inventory
            )

            // Atomic, synchronous — genuinely blocks until the write
            // has landed on disk, unlike the old UserDefaults-backed
            // save.
            try data.write(
                to: fileURL,
                options: .atomic
            )

            clearPersistenceError(
                for: .saving
            )
        } catch {
            print(
                "Failed to save equipment inventory: \(error)"
            )

            setPersistenceError(
                operation: .saving,
                message:
                    "Couldn't save equipment inventory."
            )
        }
    }

    // MARK: - File Location

    /// `nonisolated` so it can be used as a default parameter value in
    /// `init` — a `@MainActor`-isolated static function can't be
    /// referenced there, even though this one is a pure, stateless URL
    /// computation with no actual dependency on main-actor state.
    private nonisolated static func defaultFileURL() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportDirectory
            .appendingPathComponent("MyWorkout", isDirectory: true)
            .appendingPathComponent("equipment_inventory.json", isDirectory: false)
    }

    private func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()

        guard !FileManager.default.fileExists(atPath: directoryURL.path) else {
            return
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Inventory Management

    func resetToDefault(
        unit: UnitSystem
    ) {
        inventory =
            EquipmentInventory.defaultInventory

        if unit == .pounds {
            sort()
            save()
            return
        }

        convertInventory(
            to: unit
        )
    }

    func addPlate(
        weight: Double,
        quantity: Int
    ) {
        guard weight > 0,
              quantity > 0 else {
            return
        }

        inventory.plates.append(
            PlateInventory(
                weight: weight,
                quantity: quantity
            )
        )

        sort()
        save()
    }

    func addDumbbell(
        weight: Double,
        quantity: Int
    ) {
        guard weight > 0,
              quantity > 0 else {
            return
        }

        inventory.dumbbells.append(
            DumbbellInventory(
                weight: weight,
                quantity: quantity
            )
        )

        sort()
        save()
    }

    func deletePlates(
        at offsets: IndexSet
    ) {
        inventory.plates.remove(
            atOffsets: offsets
        )

        save()
    }

    func deleteDumbbells(
        at offsets: IndexSet
    ) {
        inventory.dumbbells.remove(
            atOffsets: offsets
        )

        save()
    }

    func deletePlate(
        id: UUID
    ) {
        inventory.plates.removeAll {
            $0.id == id
        }

        save()
    }

    func deleteDumbbell(
        id: UUID
    ) {
        inventory.dumbbells.removeAll {
            $0.id == id
        }

        save()
    }

    func replace(
        with newInventory: EquipmentInventory
    ) {
        inventory = newInventory

        sort()
        save()
    }

    // MARK: - Loading Increments

    func smallestPlateIncrement() -> Int {
        let smallestPlateInCurrentUnit =
            inventory.plates
                .filter {
                    $0.quantity >= 2
                }
                .map(\.weight)
                .min()
            ?? 2.5

        let smallestPlateInPounds =
            WeightConversion.toPounds(
                smallestPlateInCurrentUnit,
                from: inventory.unitSystem
            )

        return max(
            1,
            Int(
                (
                    smallestPlateInPounds
                    * 2
                )
                .rounded()
            )
        )
    }

    // MARK: - Unit Conversion

    func convertInventory(
        to newUnit: UnitSystem
    ) {
        guard newUnit != inventory.unitSystem else {
            return
        }

        inventory = EquipmentInventoryConverter.converted(
            inventory,
            to: newUnit
        )

        sort()
        save()
    }

    // MARK: - Helpers

    private func sort() {
        inventory.plates.sort {
            $0.weight > $1.weight
        }

        inventory.dumbbells.sort {
            $0.weight < $1.weight
        }
    }
}

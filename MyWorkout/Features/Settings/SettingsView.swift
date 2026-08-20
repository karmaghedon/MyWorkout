import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $settingsStore.settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .onChange(of: settingsStore.settings.appearanceMode) { _, _ in
                    settingsStore.save()
                }
            }

            Section("Workout Session") {
                Picker("Layout", selection: $settingsStore.settings.workoutSessionLayout) {
                    ForEach(WorkoutSessionLayout.allCases) { layout in
                        Text(layout.displayName).tag(layout)
                    }
                }
                .onChange(of: settingsStore.settings.workoutSessionLayout) { _, _ in
                    settingsStore.save()
                }
            }

            Section("Units") {
                Picker("Weight Unit", selection: $settingsStore.settings.unitSystem) {
                    ForEach(UnitSystem.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .onChange(of: settingsStore.settings.unitSystem) { _, newUnit in
                    equipmentStore.convertInventory(
                        to: newUnit
                    )

                    settingsStore.save()
                }
            }

            Section("Rest Timers") {
                Stepper("Compound: \(settingsStore.settings.compoundRestSeconds) sec",
                        value: $settingsStore.settings.compoundRestSeconds,
                        in: 30...600,
                        step: 15)
                    .onChange(of: settingsStore.settings.compoundRestSeconds) {_, _ in settingsStore.save() }

                Stepper("Isolation: \(settingsStore.settings.isolationRestSeconds) sec",
                        value: $settingsStore.settings.isolationRestSeconds,
                        in: 30...600,
                        step: 15)
                    .onChange(of: settingsStore.settings.isolationRestSeconds) {_, _ in settingsStore.save() }

                Stepper("Bodyweight: \(settingsStore.settings.bodyweightRestSeconds) sec",
                        value: $settingsStore.settings.bodyweightRestSeconds,
                        in: 30...600,
                        step: 15)
                    .onChange(of: settingsStore.settings.bodyweightRestSeconds) {_, _ in settingsStore.save() }
            }

            Section("Strength Formula") {
                Picker("1RM Formula", selection: $settingsStore.settings.oneRepMaxFormula) {
                    ForEach(OneRepMaxFormula.allCases) { formula in
                        Text(formula.rawValue).tag(formula)
                    }
                }
                .onChange(of: settingsStore.settings.oneRepMaxFormula) {_, _ in
                    settingsStore.save()
                }
            }

            Section("Progression Defaults") {
                Stepper("Compound Increment: \(settingsStore.settings.compoundIncrement) \(settingsStore.settings.unitSystem.rawValue)",
                        value: $settingsStore.settings.compoundIncrement,
                        in: 1...25,
                        step: 1)
                    .onChange(of: settingsStore.settings.compoundIncrement) {_, _ in settingsStore.save() }

                Stepper("Isolation Increment: \(settingsStore.settings.isolationIncrement) \(settingsStore.settings.unitSystem.rawValue)",
                        value: $settingsStore.settings.isolationIncrement,
                        in: 1...25,
                        step: 1)
                    .onChange(of: settingsStore.settings.isolationIncrement) {_, _ in settingsStore.save() }
            }
        }
        .navigationTitle("Settings")
    }
}

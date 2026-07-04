import SwiftUI

struct ExerciseSessionCardView: View {
    let exercise: Exercise
    @Binding var state: ExerciseSessionState
    let weightStep: Int
    let equipmentInventory: EquipmentInventory

    let isResting: Bool
    let restSecondsRemaining: Int
    let restTotalSeconds: Int

    let onLogSet: () -> Void
    let onStopRest: () -> Void
    let onDeleteSet: (UUID) -> Void

    @EnvironmentObject var settingsStore: UserSettingsStore

    private var weightUnit: String {
        settingsStore.settings.weightUnitLabel
    }

    private var warmups: [WarmupSet] {
        WarmupEngine.generateWarmups(for: state.weight, exerciseType: exercise.exerciseType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            header

            if let suggestion = state.suggestionMessage {
                Label(suggestion, systemImage: "arrow.up.right.circle.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.accent)
            }

            if !warmups.isEmpty {
                warmupSection
            }

            controlsSection

            if exercise.usesBarbell {
                workingLoadRow
            }

            Button(action: onLogSet) {
                Label("Log Set", systemImage: "checkmark.circle.fill")
                    .font(AppTheme.Typography.label)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)

            if isResting {
                RestTimerBadge(
                    secondsRemaining: restSecondsRemaining,
                    totalSeconds: restTotalSeconds,
                    onStop: onStopRest
                )
            }

            if !state.loggedSets.isEmpty {
                loggedSetsSection
            }

            notesSection
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(exercise.name)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Spacer(minLength: AppTheme.Spacing.md)

            VStack(alignment: .trailing, spacing: 4) {
                Text(exercise.exerciseType.rawValue.capitalized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.subtleFill))

                Text(exercise.progressionStrategy.displayName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var warmupSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("WARM-UP")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(warmups) { warmup in
                HStack {
                    Text("\(settingsStore.settings.displayWeight(warmup.weight)) \(weightUnit) × \(warmup.reps)")
                        .font(AppTheme.Typography.caption)

                    if exercise.usesBarbell {
                        Spacer()
//                        Text("\(PlateCalculator.loading(for: warmup.weight, inventory: equipmentInventory).displayText(settings: settingsStore.settings)) / side")
                        let loading = PlateCalculator.loading(
                            for: warmup.weight,
                            inventory: equipmentInventory
                        )

                        Text("\(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.subtleFill)
        )
    }

    private var controlsSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            StepperField(
                label: "Reps",
                value: $state.reps,
                range: 1...50,
                step: 1,
                suffix: nil
            )

            StepperField(
                label: "Weight",
                value: weightDisplayBinding,
                range: 0...500,
                step: displayWeightStep,
                suffix: weightUnit
            )
        }
    }

    private var workingLoadRow: some View {
        let loading = PlateCalculator.loading(for: state.weight, inventory: equipmentInventory)
//        return Text("Working load: \(loading.displayText(settings: settingsStore.settings)) / side")
        return Text("Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
    }

    private var loggedSetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("LOGGED")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(state.loggedSets) { set in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(set.setNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AppTheme.accentMuted))

                    Text("\(set.weight) \(weightUnit) × \(set.reps)")
                        .font(AppTheme.Typography.caption)

                    Spacer()

                    Button {
                        onDeleteSet(set.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete set \(set.setNumber)")
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("NOTES")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if state.notes.isEmpty {
                    Text("How did it feel?")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $state.notes)
                    .font(AppTheme.Typography.caption)
                    .frame(minHeight: 60)
                    .scrollContentBackground(.hidden)
            }
            .padding(AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.subtleFill)
            )
        }
    }
    
    private var weightDisplayBinding: Binding<Int> {
        Binding(
            get: {
                settingsStore.settings.displayWeight(state.weight)
            },
            set: { newDisplayValue in
                state.weight = settingsStore.settings.storageWeight(fromDisplayed: newDisplayValue)
            }
        )
    }

    private var displayWeightStep: Int {
        switch settingsStore.settings.unitSystem {
        case .pounds:
            return weightStep
        case .kilograms:
            return max(1, Int((Double(weightStep) * 0.453592).rounded()))
        }
    }
}

private struct StepperField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("", value: $value, format: .number)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .font(AppTheme.Typography.numeric(18))
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 36)

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Stepper("", value: $value, in: range, step: step)
                    .labelsHidden()
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.subtleFill)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

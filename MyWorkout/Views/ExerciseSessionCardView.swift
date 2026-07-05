import SwiftUI

struct ExerciseSessionCardView: View {
    let exercise: Exercise
    @Binding var state: ExerciseSessionState
    let previousSets: [LoggedSet]
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

    private var nextSetNumber: Int {
        state.loggedSets.count + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            ExerciseSessionHeaderView(
                exerciseName: exercise.name,
                exerciseType: exercise.exerciseType.rawValue.capitalized,
                progressionStrategy: exercise.progressionStrategy.displayName,
                nextSetNumber: nextSetNumber
            )

            if let suggestion = state.suggestionMessage {
                suggestionBanner(suggestion)
            }

            PreviousPerformanceView(
                previousSets: previousSets,
                displayWeight: settingsStore.settings.displayWeight,
                weightUnit: weightUnit
            )

            CurrentSetCardView(
                weight: weightDisplayBinding,
                reps: $state.reps,
                weightRange: 0...500,
                weightStep: displayWeightStep,
                weightUnit: weightUnit,
                repRange: 1...50,
                nextSetNumber: nextSetNumber,
                onLogSet: onLogSet
            )

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

            DisclosureGroup("Warm-up & plates") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    if !warmups.isEmpty {
                        warmupSection
                    }

                    if exercise.usesBarbell {
                        workingLoadRow
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            .font(AppTheme.Typography.label)
            .tint(AppTheme.accent)

            notesSection
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func suggestionBanner(_ text: String) -> some View {
        Label(text, systemImage: "arrow.up.right.circle.fill")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.accent)
            .padding(AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.accentMuted)
            )
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
                        let loading = PlateCalculator.loading(for: warmup.weight, inventory: equipmentInventory)

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
                .fill(AppTheme.cardBackground)
        )
    }

    private var workingLoadRow: some View {
        let loading = PlateCalculator.loading(for: state.weight, inventory: equipmentInventory)

        return Label(
            "Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side",
            systemImage: "circle.grid.2x2.fill"
        )
        .font(AppTheme.Typography.caption)
        .foregroundStyle(.secondary)
    }

    private var loggedSetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TODAY")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(state.loggedSets) { set in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)

                    Text("Set \(set.setNumber)")
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(settingsStore.settings.displayWeight(set.weight)) \(weightUnit) × \(set.reps)")
                        .font(AppTheme.Typography.numeric(16))

                    Button {
                        onDeleteSet(set.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete set \(set.setNumber)")
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var notesSection: some View {
        DisclosureGroup("Notes") {
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
            .padding(.top, AppTheme.Spacing.sm)
        }
        .font(AppTheme.Typography.label)
        .tint(AppTheme.accent)
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

import SwiftUI

/// Shown after a workout is saved — the "Finish Summary" + "Workout
/// Insights" goals from the Design Blueprint's F4 phase. Distinct from
/// `WorkoutSessionDialogs`' "Finish Workout?" confirmation, which still
/// gates the save itself; this screen appears only after that save
/// already happened.
struct WorkoutFinishSummaryView: View {
    let log: WorkoutLog
    let previousLog: WorkoutLog?
    let newPersonalRecords: [PersonalRecord]
    let onDone: () -> Void

    @EnvironmentObject private var settingsStore: UserSettingsStore

    private var totalSets: Int {
        log.completedExercises.reduce(0) { $0 + $1.sets.count }
    }

    private var totalVolume: Double {
        WorkoutSessionEngine.totalVolume(in: log)
    }

    private var volumeChangeText: String? {
        guard let previousLog else {
            return nil
        }

        let previousVolume = WorkoutSessionEngine.totalVolume(in: previousLog)

        guard previousVolume > 0 else {
            return nil
        }

        let percentChange = Int(
            (((totalVolume - previousVolume) / previousVolume) * 100)
                .rounded()
        )

        switch percentChange {
        case 0:
            return "Same total volume as last time"
        case let change where change > 0:
            return "+\(change)% volume vs last time"
        default:
            return "\(percentChange)% volume vs last time"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.success)
                        .accessibilityHidden(true)

                    Text("Workout Complete")
                        .font(AppTheme.Typography.heroTitle)

                    Text(log.workoutName)
                        .font(AppTheme.Typography.label)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.lg)

                AppCard {
                    HStack(spacing: AppTheme.Spacing.md) {
                        MetricView(
                            label: "Duration",
                            value: log.durationSeconds.map {
                                ActiveWorkoutStore.formatDuration($0)
                            } ?? "—"
                        )

                        MetricView(
                            label: "Exercises",
                            value: "\(log.completedExercises.count)"
                        )

                        MetricView(
                            label: "Sets",
                            value: "\(totalSets)"
                        )
                    }
                }
                .padding(.horizontal)

                if let volumeChangeText {
                    AppCard {
                        Label(volumeChangeText, systemImage: "chart.bar.fill")
                            .font(AppTheme.Typography.label)
                    }
                    .padding(.horizontal)
                }

                if !newPersonalRecords.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        SectionHeader(title: "New Personal Records")
                            .padding(.horizontal)

                        AppCard(backgroundColor: AppTheme.accentMuted) {
                            VStack(spacing: AppTheme.Spacing.md) {
                                ForEach(
                                    Array(newPersonalRecords.enumerated()),
                                    id: \.element.id
                                ) { index, record in
                                    HStack(spacing: AppTheme.Spacing.md) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundStyle(.yellow)
                                            .accessibilityHidden(true)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(record.exerciseName)
                                                .font(AppTheme.Typography.cardTitle)

                                            Text(
                                                "\(formatWeight(settingsStore.settings.displayWeight(record.weightPounds))) "
                                                + "\(settingsStore.settings.weightUnitLabel) × \(record.reps)"
                                            )
                                            .font(AppTheme.Typography.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .accessibilityElement(children: .combine)

                                    if index < newPersonalRecords.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                PrimaryButton(title: "Done", action: onDone)
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.sm)
            }
            .padding(.bottom)
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
}

import SwiftUI

struct StartWorkoutView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore

    @State private var showWorkoutSession = false
    @State private var workoutPendingStart: Workout?
    @State private var showActiveWorkoutWarning = false
    @State private var showCancelActiveWorkoutConfirmation = false

    var body: some View {
        List {
            if let activeWorkout = activeWorkoutStore.activeWorkout {
                Section("Active Workout") {
                    Button {
                        showWorkoutSession = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Resume \(activeWorkout.name)")
                                .font(AppTheme.Typography.cardTitle)

                            Text("Workout in progress • \(activeWorkoutStore.formattedElapsedTime)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        showCancelActiveWorkoutConfirmation = true
                    } label: {
                        Label("Cancel Active Workout", systemImage: "xmark.circle")
                    }
                    .accessibilityHint("Discards this workout and all logged sets. Asks for confirmation first.")
                }
            }

            Section("Templates") {
                ForEach(templateStore.templates) { template in
                    Button {
                        handleTemplateTap(template)
                    } label: {
                        row(for: template)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay {
            if templateStore.templates.isEmpty {
                emptyState
            }
        }
        .navigationTitle("Start Workout")
        .navigationDestination(isPresented: $showWorkoutSession) {
            WorkoutSessionView()
        }
        .confirmationDialog(
            "Active workout in progress",
            isPresented: $showActiveWorkoutWarning,
            titleVisibility: .visible
        ) {
            Button("Resume Active Workout") {
                workoutPendingStart = nil
                showWorkoutSession = true
            }

            Button(
                "Cancel Active Workout and Start New",
                role: .destructive
            ) {
                guard let workout = workoutPendingStart else {
                    return
                }

                activeWorkoutStore.replaceActiveWorkout(
                    with: workout
                )

                workoutPendingStart = nil
                showWorkoutSession = true
            }

            Button("Keep Current Workout", role: .cancel) {
                workoutPendingStart = nil
            }
        } message: {
            Text("You already have a workout running. Starting a new one will discard the active session.")
        }
        .confirmationDialog(
            "Cancel Active Workout?",
            isPresented: $showCancelActiveWorkoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Workout", role: .destructive) {
                activeWorkoutStore.cancel()
            }

            Button("Keep Workout", role: .cancel) {}
        } message: {
            Text("This will discard the current workout and all logged sets. This cannot be undone.")
        }
    }

    private func handleTemplateTap(
        _ template: WorkoutTemplate
    ) {
        let workout = Workout(
            name: template.name,
            exercises: template.exercises
        )

        switch activeWorkoutStore.start(workout) {
        case .started:
            showWorkoutSession = true

        case .activeWorkoutAlreadyExists:
            workoutPendingStart = workout
            showActiveWorkoutWarning = true
        }
    }

    private func row(for template: WorkoutTemplate) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            WorkoutCard(
                systemImage: "figure.strengthtraining.traditional",
                title: template.name
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    Text(lastPerformedText(for: template))
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
    }

    private var emptyState: some View {
        AppEmptyStateView(
            title: "No Templates Yet",
            message: "Build a workout template first, then start it from here.",
            systemImage: "figure.strengthtraining.traditional"
        )
    }

    private func lastPerformedText(for template: WorkoutTemplate) -> String {
        let mostRecent = logStore.logs
            .filter { $0.workoutName == template.name }
            .map(\.date)
            .max()

        guard let mostRecent else {
            return "Not started yet"
        }

        return "Last done \(mostRecent.formatted(.relative(presentation: .named)))"
    }
}

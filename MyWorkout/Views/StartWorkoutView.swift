import SwiftUI

struct StartWorkoutView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore

    @State private var showWorkoutSession = false

    var body: some View {
        List {
            if let activeWorkout = activeWorkoutStore.activeWorkout {
                Section("Active Workout") {
                    Button {
                        showWorkoutSession = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Resume \(activeWorkout.name)")
                                .font(.headline)

                            Text("Workout in progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        activeWorkoutStore.cancel()
                    } label: {
                        Label("Cancel Active Workout", systemImage: "xmark.circle")
                    }
                }
            }

            Section("Templates") {
                ForEach(templateStore.templates) { template in
                    Button {
                        let workout = Workout(
                            name: template.name,
                            exercises: template.exercises
                        )

                        activeWorkoutStore.start(workout)
                        showWorkoutSession = true
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
    }

    private func row(for template: WorkoutTemplate) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.accentMuted)

                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.headline)

                Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(lastPerformedText(for: template))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Templates Yet")
                .font(.headline)

            Text("Build a workout template first, then start it from here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
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

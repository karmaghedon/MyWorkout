import SwiftUI

struct ExerciseSessionHeaderView: View {
    let exercise: Exercise
    let exerciseType: String
    let progressionStrategy: String
    let nextSetNumber: Int

    @State private var showsExerciseDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Button {
                    showsExerciseDetail = true
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                        Text(exercise.name)
                            .font(AppTheme.Typography.screenTitle)
                            .foregroundStyle(Color.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)

                        Image(systemName: "info.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(exercise.name), view exercise info")

                Spacer(minLength: AppTheme.Spacing.md)

                Chip(
                    text: "Set \(nextSetNumber)",
                    font: AppTheme.Typography.label,
                    backgroundColor: AppTheme.accentMuted,
                    foregroundColor: Color.primary
                )
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exerciseType)
                Text("•")
                Text(progressionStrategy)
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showsExerciseDetail) {
            NavigationStack {
                ExerciseDetailView(exercise: exercise, showsDoneButton: true)
            }
        }
    }
}

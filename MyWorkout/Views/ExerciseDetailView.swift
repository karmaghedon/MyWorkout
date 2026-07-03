import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(exercise.muscleGroup)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(exercise.equipment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Instructions")
                        .font(AppTheme.Typography.sectionTitle)

                    Text(exercise.instructions)
                        .font(.body)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle(exercise.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

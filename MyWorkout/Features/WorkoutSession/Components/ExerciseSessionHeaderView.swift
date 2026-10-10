import SwiftUI

struct ExerciseSessionHeaderView: View {
    let exercise: Exercise
    let exerciseType: String
    let progressionStrategy: String
    let loggedSetCount: Int
    let targetSetCount: Int

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
                    text: "Set \(loggedSetCount)/\(targetSetCount)",
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

extension ExerciseSessionHeaderView {
    /// Stable scroll-anchor id for the header itself, distinct from the
    /// exercise card's own id — same reasoning as
    /// `RestTimerBadge.scrollAnchorID`. The card can be much taller than
    /// the screen (warm-ups, several logged sets, notes), so scrolling to
    /// center the *card* can leave this header — the only place showing
    /// the exercise name and set progress together — scrolled off the
    /// top of the screen. Scrolling to this id instead keeps it in view.
    static func scrollAnchorID(for exerciseID: UUID) -> String {
        "exerciseHeader_\(exerciseID.uuidString)"
    }
}

import SwiftUI

struct CustomExerciseRow: View {
    enum Style {
        case active
        case archived
    }

    let exercise: Exercise
    let style: Style
    let onSelect: () -> Void
    let onArchive: () -> Void
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        switch style {
        case .active:
            activeRow

        case .archived:
            archivedRow
        }
    }

    private var activeRow: some View {
        Button(action: onSelect) {
            HStack(
                spacing: AppTheme.Spacing.sm
            ) {
                exerciseDescription

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(exercise.name), \(summary)"
        )
        .accessibilityHint(
            "Opens this custom exercise for editing."
        )
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            Button(
                role: .destructive,
                action: onArchive
            ) {
                Label(
                    "Archive",
                    systemImage: "archivebox"
                )
            }
        }
    }

    private var archivedRow: some View {
        HStack(
            spacing: AppTheme.Spacing.sm
        ) {
            exerciseDescription

            Spacer()

            Button(action: onRestore) {
                Label(
                    "Restore",
                    systemImage: "arrow.uturn.backward"
                )
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                "Restore \(exercise.name)"
            )
            .accessibilityHint(
                "Makes this exercise active again."
            )
        }
        .contentShape(Rectangle())
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            Button(
                role: .destructive,
                action: onDelete
            ) {
                Label(
                    "Delete",
                    systemImage: "trash"
                )
            }
        }
    }

    private var exerciseDescription: some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        "\(exercise.muscleGroup.displayName) · "
        + exercise.equipment.displayName
    }
}

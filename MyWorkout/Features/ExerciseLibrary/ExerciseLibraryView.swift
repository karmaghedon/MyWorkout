import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject private var customExerciseStore:
        CustomExerciseStore

    private var exercises: [Exercise] {
        ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExerciseStore.activeExercises
                )
            ]
        ).exercises
    }

    @State private var expandedGroups: Set<MuscleGroup> = []

    private let initialDisplayCount = 10

    private var groupedExercises: [
        (muscleGroup: MuscleGroup, exercises: [Exercise])
    ] {
        let grouped = Dictionary(
            grouping: exercises,
            by: \.muscleGroup
        )

        return grouped
            .map {
                (
                    muscleGroup: $0.key,
                    exercises: $0.value.sorted {
                        $0.name < $1.name
                    }
                )
            }
            .sorted {
                $0.muscleGroup < $1.muscleGroup
            }
    }

    var body: some View {
        List {
            ForEach(
                groupedExercises,
                id: \.muscleGroup
            ) { group in
                Section(
                    group.muscleGroup.displayName
                ) {
                    let isExpanded = expandedGroups.contains(
                        group.muscleGroup
                    )

                    let displayedExercises = isExpanded
                        ? group.exercises
                        : Array(
                            group.exercises.prefix(
                                initialDisplayCount
                            )
                        )

                    let hasMore =
                        group.exercises.count > initialDisplayCount

                    ForEach(displayedExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(
                                exercise: exercise
                            )
                        } label: {
                            ExerciseRowView(
                                exercise: exercise
                            )
                        }
                    }

                    if hasMore && !isExpanded {
                        Button {
                            expandedGroups.insert(
                                group.muscleGroup
                            )
                        } label: {
                            HStack {
                                Spacer()

                                Text(
                                    "Show \(group.exercises.count - initialDisplayCount) more"
                                )
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(.secondary)

                                Spacer()
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AppRoute.customExercises) {
                    Label("Custom Exercises", systemImage: "figure.strengthtraining.functional")
                }
            }
        }
    }
}

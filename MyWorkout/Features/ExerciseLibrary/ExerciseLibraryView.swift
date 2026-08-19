import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject private var customExerciseStore:
        CustomExerciseStore
    @EnvironmentObject private var favoriteExercisesStore:
        FavoriteExercisesStore

    private var allExercises: [Exercise] {
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
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var selectedDifficulty: String?
    @State private var showFavoritesOnly = false

    private let initialDisplayCount = 10

    // MARK: - Filtering

    private var equipmentOptions: [ExerciseEquipment] {
        Array(Set(allExercises.map(\.equipment))).sorted()
    }

    private var difficultyOptions: [String] {
        Array(Set(allExercises.map(\.difficulty))).sorted()
    }

    private var hasActiveFilters: Bool {
        selectedEquipment != nil
            || selectedDifficulty != nil
            || showFavoritesOnly
    }

    private var exercises: [Exercise] {
        allExercises.filter { exercise in
            if let selectedEquipment, exercise.equipment != selectedEquipment {
                return false
            }

            if let selectedDifficulty, exercise.difficulty != selectedDifficulty {
                return false
            }

            if showFavoritesOnly, !favoriteExercisesStore.isFavorite(exercise.id) {
                return false
            }

            return true
        }
    }

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
            if exercises.isEmpty {
                emptyFilterState
            }

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
                        exerciseRow(for: exercise)
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
            ToolbarItemGroup(placement: .primaryAction) {
                filterMenu

                NavigationLink(value: AppRoute.customExercises) {
                    Label("Custom Exercises", systemImage: "figure.strengthtraining.functional")
                }
            }
        }
    }

    // MARK: - Row

    private func exerciseRow(for exercise: Exercise) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            NavigationLink {
                ExerciseDetailView(
                    exercise: exercise
                )
            } label: {
                ExerciseRowView(
                    exercise: exercise
                )
            }

            IconButton(
                systemImage: favoriteExercisesStore.isFavorite(exercise.id)
                    ? "star.fill"
                    : "star",
                accessibilityLabel: favoriteExercisesStore.isFavorite(exercise.id)
                    ? "Remove \(exercise.name) from favorites"
                    : "Add \(exercise.name) to favorites",
                color: favoriteExercisesStore.isFavorite(exercise.id)
                    ? .yellow
                    : AppTheme.tertiaryText
            ) {
                favoriteExercisesStore.toggleFavorite(exercise.id)
            }
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Toggle("Favorites Only", isOn: $showFavoritesOnly)

            Picker("Equipment", selection: $selectedEquipment) {
                Text("All Equipment").tag(ExerciseEquipment?.none)

                ForEach(equipmentOptions) { equipment in
                    Text(equipment.displayName).tag(Optional(equipment))
                }
            }

            Picker("Difficulty", selection: $selectedDifficulty) {
                Text("All Difficulties").tag(String?.none)

                ForEach(difficultyOptions, id: \.self) { difficulty in
                    Text(difficulty).tag(Optional(difficulty))
                }
            }

            if hasActiveFilters {
                Button("Clear Filters", role: .destructive) {
                    selectedEquipment = nil
                    selectedDifficulty = nil
                    showFavoritesOnly = false
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: hasActiveFilters
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
    }

    private var emptyFilterState: some View {
        AppEmptyStateView(
            title: "No Matching Exercises",
            message: "Try a different filter combination.",
            systemImage: "line.3.horizontal.decrease.circle"
        )
        .listRowSeparator(.hidden)
    }
}

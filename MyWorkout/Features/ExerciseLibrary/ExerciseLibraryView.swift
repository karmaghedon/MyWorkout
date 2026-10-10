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
    @State private var selectedMuscleGroupTab: MuscleGroup?
    @State private var searchText = ""

    private let initialDisplayCount = 10

    // MARK: - Filtering

    /// Every muscle group actually present, in the same order
    /// `groupedExercises` sections appear in — sourced from
    /// `allExercises` rather than the already-filtered `exercises` so
    /// switching an Equipment/Difficulty filter doesn't make an option
    /// disappear out from under the user mid-browse.
    private var muscleGroupOptions: [MuscleGroup] {
        Array(Set(allExercises.map(\.muscleGroup))).sorted()
    }

    private var equipmentOptions: [ExerciseEquipment] {
        Array(Set(allExercises.map(\.equipment))).sorted()
    }

    /// Beginner → Intermediate → Advanced, not alphabetical (which would
    /// read "Advanced, Beginner, Intermediate"). Any difficulty string
    /// outside this canonical set — none exist today, since custom
    /// exercises only offer these three — sorts alphabetically after it.
    private var difficultyOptions: [String] {
        let canonicalOrder = ["Beginner", "Intermediate", "Advanced"]

        return Array(Set(allExercises.map(\.difficulty))).sorted { lhs, rhs in
            let lhsRank = canonicalOrder.firstIndex(of: lhs) ?? canonicalOrder.count
            let rhsRank = canonicalOrder.firstIndex(of: rhs) ?? canonicalOrder.count

            guard lhsRank == rhsRank else {
                return lhsRank < rhsRank
            }

            return lhs < rhs
        }
    }

    private var hasActiveFilters: Bool {
        selectedEquipment != nil
            || selectedDifficulty != nil
            || showFavoritesOnly
    }

    private var exercises: [Exercise] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return allExercises.filter { exercise in
            if let selectedEquipment, exercise.equipment != selectedEquipment {
                return false
            }

            if let selectedDifficulty, exercise.difficulty != selectedDifficulty {
                return false
            }

            if showFavoritesOnly, !favoriteExercisesStore.isFavorite(exercise) {
                return false
            }

            if let selectedMuscleGroupTab, exercise.muscleGroup != selectedMuscleGroupTab {
                return false
            }

            if !trimmedSearch.isEmpty, !exercise.name.localizedCaseInsensitiveContains(trimmedSearch) {
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
        VStack(spacing: 0) {
            muscleGroupPicker
                .padding(.horizontal)
                .padding(.vertical, AppTheme.Spacing.sm)

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
        }
        .navigationTitle("Exercise Library")
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                filterMenu

                NavigationLink(value: AppRoute.customExercises) {
                    Label("Custom Exercises", systemImage: "figure.strengthtraining.functional")
                }
            }
        }
    }

    // MARK: - Muscle Group Picker

    /// A dropdown rather than a scrolling tab row — with a dozen-plus
    /// muscle groups, a row of tabs either scrolled out of view or
    /// crowded the screen; a single compact dropdown shows the current
    /// selection and lets you pick any body part in one tap, same
    /// native `.pickerStyle(.menu)` idiom the Equipment/Difficulty
    /// filters already use inside the Filter menu.
    private var muscleGroupPicker: some View {
        HStack {
            Picker("Body Part", selection: $selectedMuscleGroupTab) {
                Text("All Body Parts").tag(MuscleGroup?.none)

                ForEach(muscleGroupOptions) { group in
                    Text(group.displayName).tag(Optional(group))
                }
            }
            .pickerStyle(.menu)

            Spacer()
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
                systemImage: favoriteExercisesStore.isFavorite(exercise)
                    ? "star.fill"
                    : "star",
                accessibilityLabel: favoriteExercisesStore.isFavorite(exercise)
                    ? "Remove \(exercise.name) from favorites"
                    : "Add \(exercise.name) to favorites",
                color: favoriteExercisesStore.isFavorite(exercise)
                    ? AppTheme.accent
                    : AppTheme.tertiaryText
            ) {
                favoriteExercisesStore.toggleFavorite(exercise)
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

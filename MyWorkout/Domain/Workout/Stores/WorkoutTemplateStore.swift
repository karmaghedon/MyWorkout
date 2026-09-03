import Foundation

@MainActor
final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any WorkoutTemplateRepository
    private let builtInRegistry: ExerciseRegistry

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.workouttemplatestore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted templates from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any WorkoutTemplateRepository =
            FileWorkoutTemplateRepository(),
        builtInRegistry: ExerciseRegistry = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource()
            ]
        )
    ) {
        self.repository = repository
        self.builtInRegistry = builtInRegistry

        load()

        if templates.isEmpty,
           persistenceError == nil {
            templates = SeedData.defaultTemplates.map {
                refreshed($0)
            }

            save()
        }
    }

    // MARK: - Template Actions

    func add(_ template: WorkoutTemplate) {
        templates.append(
            refreshed(template)
        )

        save()
    }

    func delete(at offsets: IndexSet) {
        templates.remove(
            atOffsets: offsets
        )

        save()
    }

    func update(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(
            where: { $0.id == template.id }
        ) else {
            return
        }

        templates[index] = refreshed(
            template
        )

        save()
    }

    func duplicate(_ template: WorkoutTemplate) {
        let copy = WorkoutTemplate(
            id: UUID(),
            name: duplicateName(
                for: template.name
            ),
            exercises: template.exercises
        )

        templates.append(
            refreshed(copy)
        )

        save()
    }

    func replaceAll(
        with newTemplates: [WorkoutTemplate]
    ) {
        templates = newTemplates.map {
            refreshed($0)
        }

        save()
    }

    /// Updates each matching template's per-exercise starting weight
    /// (`Exercise.targetWeightPounds`) to the last set actually logged for
    /// that exercise in a just-finished workout — so reopening "Edit
    /// Template" later shows where the user has actually progressed to,
    /// instead of whatever value the template was created or last hand-
    /// edited with. This is purely informational: `WorkoutSessionEngine
    /// .initialState` already ignores `targetWeightPounds` once real
    /// logged history exists for an exercise (progression drives the
    /// weight then, not the template) — this only keeps the *displayed*
    /// template value honest.
    ///
    /// Matches the template by `WorkoutLog.workoutName == template.name`,
    /// the same name-based match `DashboardView`'s "Next Workout" card
    /// already uses — and inherits the same known limitation: renaming a
    /// template after workouts were logged under its old name orphans
    /// this sync too, same as it orphans that card's match.
    func syncStartingWeights(from log: WorkoutLog) {
        var didUpdate = false

        for templateIndex in templates.indices
        where templates[templateIndex].name == log.workoutName {

            for exerciseIndex in
                templates[templateIndex].exercises.indices {

                let exercise =
                    templates[templateIndex]
                        .exercises[exerciseIndex]

                guard let lastSet = completedExercise(
                    for: exercise,
                    in: log
                )?.sets.last else {
                    continue
                }

                guard templates[templateIndex]
                        .exercises[exerciseIndex]
                        .targetWeightPounds != lastSet.weight else {
                    continue
                }

                templates[templateIndex]
                    .exercises[exerciseIndex]
                    .targetWeightPounds = lastSet.weight

                didUpdate = true
            }
        }

        guard didUpdate else {
            return
        }

        save()
    }

    /// Matches by `Exercise.id` first (stable for both built-in and
    /// custom exercises), falling back to normalized name for the rare
    /// case an id doesn't resolve — same defensive two-step lookup
    /// `ExerciseRegistry.exercise(id:name:)` already uses elsewhere.
    private func completedExercise(
        for exercise: Exercise,
        in log: WorkoutLog
    ) -> CompletedExercise? {
        if let match = log.completedExercises.first(
            where: { $0.exerciseID == exercise.id }
        ) {
            return match
        }

        let normalizedName = ExerciseNameValidator.normalize(exercise.name)

        return log.completedExercises.first {
            ExerciseNameValidator.normalize($0.exerciseName) == normalizedName
        }
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation
                == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Duplicate Naming

    private func duplicateName(
        for originalName: String
    ) -> String {
        let baseName =
            "\(originalName) Copy"

        guard templates.contains(
            where: {
                $0.name == baseName
            }
        ) else {
            return baseName
        }

        var copyNumber = 2

        while templates.contains(
            where: {
                $0.name
                    == "\(baseName) \(copyNumber)"
            }
        ) {
            copyNumber += 1
        }

        return
            "\(baseName) \(copyNumber)"
    }

    // MARK: - Persistence

    private func load() {
        do {
            let loadedTemplates =
                try repository.load()

            templates = loadedTemplates.map {
                refreshed($0)
            }

            isPersistenceWritable = true

            clearPersistenceError(
                for: .loading
            )
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to load workout templates: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your workout templates. "
                    + "The existing template data was preserved "
                    + "and will not be overwritten."
            )
        }
    }

    /// Blocks until any save already queued by `save()` has actually
    /// finished writing to disk — call when the app is about to
    /// background or terminate, since `save()`'s dispatch to
    /// `saveQueue` is not otherwise guaranteed to complete before the
    /// process is suspended or killed.
    func flushPendingSave() {
        saveQueue.sync {}
    }

    private func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your workout templates could not be read, "
                    + "so they were not overwritten. Restart "
                    + "the app or restore a valid backup before "
                    + "saving more templates."
            )

            return
        }

        let templatesToSave = templates
        let repository = repository

        saveQueue.async { [weak self] in
            do {
                try repository.save(
                    templatesToSave
                )

                DispatchQueue.main.async {
                    self?.clearPersistenceError(
                        for: .saving
                    )
                }
            } catch {
                print(
                    "Failed to save workout templates: \(error)"
                )

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message:
                            "Couldn't save workout templates."
                    )
                }
            }
        }
    }

    // MARK: - Exercise Refresh

    /// Re-resolves each saved exercise against the current built-in
    /// definition (by id, falling back to name) so a template stays in
    /// sync with any changes to `SeedData` after it was created —
    /// instructions, muscle group, and so on.
    ///
    /// `targetSets`/`targetWeightPounds`/`supersetGroupID`/
    /// `progressionRule` are per-*template* overrides (see
    /// `Exercise.swift`), not part of the built-in exercise's own
    /// identity, so they have to survive this refresh explicitly: the
    /// freshly-looked-up built-in `Exercise` always carries the global
    /// defaults, and naively swapping in that whole value would silently
    /// discard whatever the user configured for this template every time
    /// it's saved or loaded.
    private func refreshed(
        _ template: WorkoutTemplate
    ) -> WorkoutTemplate {
        WorkoutTemplate(
            id: template.id,
            name: template.name,
            exercises: template.exercises.map {
                savedExercise in

                guard var refreshedExercise = builtInRegistry.exercise(
                    id: savedExercise.id,
                    name: savedExercise.name
                ) else {
                    return savedExercise
                }

                refreshedExercise.targetSets = savedExercise.targetSets
                refreshedExercise.targetWeightPounds = savedExercise.targetWeightPounds
                refreshedExercise.supersetGroupID = savedExercise.supersetGroupID
                refreshedExercise.progressionRule = savedExercise.progressionRule

                return refreshedExercise
            }
        )
    }
}

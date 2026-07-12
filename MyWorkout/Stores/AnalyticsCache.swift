import Foundation
import Combine

@MainActor
final class AnalyticsCache: ObservableObject {
    @Published private(set) var recoveryWarnings: [RecoveryWarning] = []
    @Published private(set) var performanceWarnings: [ExercisePerformanceWarning] = []
    @Published private(set) var totalSets = 0

    @Published private(set)
    var volumeByMuscleGroup: [
        (muscle: String, sets: Int)
    ] = []

    @Published private(set)
    var personalRecords: [
        (exercise: String, weight: Double, reps: Int)
    ] = []

    private var cancellable: AnyCancellable?

    // MARK: - Binding

    /// Observes workout logs and templates because both can affect analytics.
    ///
    /// Logs provide performance data.
    /// Templates provide exercise metadata through ExerciseRegistry.
    func bind(
        to logStore: WorkoutLogStore,
        templateStore: WorkoutTemplateStore
    ) {
        guard cancellable == nil else {
            return
        }

        cancellable = Publishers.CombineLatest(
            logStore.$logs,
            templateStore.$templates
        )
        .debounce(
            for: .milliseconds(300),
            scheduler: DispatchQueue.main
        )
        .sink { [weak self] logs, templates in
            self?.recompute(
                logs: logs,
                templates: templates
            )
        }
    }

    // MARK: - Recalculation

    private func recompute(
        logs: [WorkoutLog],
        templates: [WorkoutTemplate]
    ) {
        let registry = ExerciseRegistryFactory.make(
            templates: templates,
            logs: logs
        )

        recoveryWarnings = RecoveryAnalyzer.warnings(
            logs: logs,
            registry: registry
        )

        performanceWarnings =
            ExercisePerformanceAnalyzer.warnings(
                logs: logs
            )

        totalSets = logs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) {
                $0 + $1.sets.count
            }
        }

        volumeByMuscleGroup =
            computeVolumeByMuscleGroup(
                logs: logs,
                registry: registry
            )

        personalRecords = computePersonalRecords(
            logs: logs
        )
    }

    // MARK: - Volume

    private func computeVolumeByMuscleGroup(
        logs: [WorkoutLog],
        registry: ExerciseRegistry
    ) -> [(muscle: String, sets: Int)] {
        var result: [String: Int] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                guard let exercise = registry.exercise(
                    id: completedExercise.exerciseID,
                    name: completedExercise.exerciseName
                ) else {
                    continue
                }

                result[
                    exercise.muscleGroup.displayName,
                    default: 0
                ] += completedExercise.sets.count
            }
        }

        return result
            .map {
                (
                    muscle: $0.key,
                    sets: $0.value
                )
            }
            .sorted {
                if $0.sets != $1.sets {
                    return $0.sets > $1.sets
                }

                return $0.muscle
                    .localizedCaseInsensitiveCompare(
                        $1.muscle
                    ) == .orderedAscending
            }
    }

    // MARK: - Personal Records

    private func computePersonalRecords(
        logs: [WorkoutLog]
    ) -> [
        (
            exercise: String,
            weight: Double,
            reps: Int
        )
    ] {
        var bestByExercise: [
            String: (
                name: String,
                set: LoggedSet
            )
        ] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                let key =
                    completedExercise.exerciseID?.uuidString
                    ?? completedExercise.exerciseName

                for set in completedExercise.sets {
                    guard let currentBest =
                        bestByExercise[key]?.set else {
                        bestByExercise[key] = (
                            name:
                                completedExercise.exerciseName,
                            set: set
                        )

                        continue
                    }

                    if isBetter(
                        set,
                        than: currentBest
                    ) {
                        bestByExercise[key] = (
                            name:
                                completedExercise.exerciseName,
                            set: set
                        )
                    }
                }
            }
        }

        return bestByExercise
            .map {
                (
                    exercise: $0.value.name,
                    weight: $0.value.set.weight,
                    reps: $0.value.set.reps
                )
            }
            .sorted {
                $0.exercise.localizedCaseInsensitiveCompare(
                    $1.exercise
                ) == .orderedAscending
            }
    }

    private func isBetter(
        _ newSet: LoggedSet,
        than oldSet: LoggedSet
    ) -> Bool {
        if newSet.weight != oldSet.weight {
            return newSet.weight > oldSet.weight
        }

        return newSet.reps > oldSet.reps
    }
}

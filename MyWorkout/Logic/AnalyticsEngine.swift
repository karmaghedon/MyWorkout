import Foundation

struct AnalyticsEngine {
    func makeSnapshot(
        logs: [WorkoutLog],
        registry: ExerciseRegistry
    ) -> AnalyticsSnapshot {
        AnalyticsSnapshot(
            totalSets: totalSetCount(in: logs),
            volumeByMuscleGroup:
                volumeByMuscleGroup(
                    logs: logs,
                    registry: registry
                ),
            personalRecords:
                personalRecords(in: logs),
            recoveryWarnings:
                RecoveryAnalyzer.warnings(
                    logs: logs,
                    registry: registry
                ),
            performanceWarnings:
                ExercisePerformanceAnalyzer.warnings(
                    logs: logs
                )
        )
    }

    // MARK: - Total Sets

    private func totalSetCount(
        in logs: [WorkoutLog]
    ) -> Int {
        logs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) {
                $0 + $1.sets.count
            }
        }
    }

    // MARK: - Volume

    private func volumeByMuscleGroup(
        logs: [WorkoutLog],
        registry: ExerciseRegistry
    ) -> [MuscleGroupVolume] {
        var result: [MuscleGroup: Int] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                guard let exercise = registry.exercise(
                    id: completedExercise.exerciseID,
                    name: completedExercise.exerciseName
                ) else {
                    continue
                }

                result[
                    exercise.muscleGroup,
                    default: 0
                ] += completedExercise.sets.count
            }
        }

        return result
            .map {
                MuscleGroupVolume(
                    muscleGroup: $0.key,
                    setCount: $0.value
                )
            }
            .sorted {
                if $0.setCount != $1.setCount {
                    return $0.setCount > $1.setCount
                }

                return $0.muscleGroup.displayName
                    .localizedCaseInsensitiveCompare(
                        $1.muscleGroup.displayName
                    ) == .orderedAscending
            }
    }

    // MARK: - Personal Records

    private func personalRecords(
        in logs: [WorkoutLog]
    ) -> [PersonalRecord] {
        struct RecordCandidate {
            let exerciseID: UUID?
            let exerciseName: String
            let set: LoggedSet
        }

        var bestByExercise: [String: RecordCandidate] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                let key =
                    completedExercise.exerciseID?.uuidString
                    ?? completedExercise.exerciseName

                for set in completedExercise.sets {
                    guard let currentBest =
                            bestByExercise[key]?.set else {
                        bestByExercise[key] = RecordCandidate(
                            exerciseID:
                                completedExercise.exerciseID,
                            exerciseName:
                                completedExercise.exerciseName,
                            set: set
                        )

                        continue
                    }

                    if isBetter(
                        set,
                        than: currentBest
                    ) {
                        bestByExercise[key] = RecordCandidate(
                            exerciseID:
                                completedExercise.exerciseID,
                            exerciseName:
                                completedExercise.exerciseName,
                            set: set
                        )
                    }
                }
            }
        }

        return bestByExercise
            .values
            .map {
                PersonalRecord(
                    exerciseID: $0.exerciseID,
                    exerciseName: $0.exerciseName,
                    weightPounds: $0.set.weight,
                    reps: $0.set.reps
                )
            }
            .sorted {
                $0.exerciseName
                    .localizedCaseInsensitiveCompare(
                        $1.exerciseName
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

import Foundation
import Combine

@MainActor
final class AnalyticsCache: ObservableObject {
    @Published private(set) var recoveryWarnings: [RecoveryWarning] = []
    @Published private(set) var performanceWarnings: [ExercisePerformanceWarning] = []
    @Published private(set) var totalSets: Int = 0
    @Published private(set) var volumeByMuscleGroup: [(muscle: String, sets: Int)] = []
    @Published private(set) var personalRecord: [(exercise: String, weight: Double, reps: Int)] = []
    
    private var cancellable: AnyCancellable?
    func bind(to logStore: WorkoutLogStore) {
        guard cancellable == nil else { return }
        recompute(logs: logStore.logs)
        cancellable = logStore.$logs
            .removeDuplicates { $0.count == $1.count && $0.first?.id == $1.first?.id }
            .sink { [weak self] logs in
                self?.recompute(logs: logs)
            }
    }
    
    private func recompute(logs: [WorkoutLog]) {
        recoveryWarnings = RecoveryAnalyzer.warnings(logs: logs)
        performanceWarnings = ExercisePerformanceAnalyzer.warnings(logs: logs)
        
        totalSets = logs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) { $0 + $1.sets.count }
        }
        
        volumeByMuscleGroup = computeVolumeByMuscleGroup(logs: logs)
        personalRecord = computePersonalRecords(logs: logs)
    }
    
    private func computeVolumeByMuscleGroup(logs: [WorkoutLog]) -> [(muscle: String, sets: Int)] {
        var result: [String: Int] = [:]
        
        for log in logs {
            for completedExercise in log.completedExercises {
                guard let exercise = ExerciseRegistry.find(for: completedExercise) else {
                    continue
                }
                result[exercise.muscleGroup, default: 0] += completedExercise.sets.count
            }
        }
        
        return result
            .map { (muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
    }
    
    private func computePersonalRecords(logs: [WorkoutLog]) -> [(exercise: String, weight: Double, reps: Int)] {
        var bestByExercise: [String: (name: String, set: LoggedSet)] = [:]
        
        for log in logs {
            for completedExercise in log.completedExercises {
                let key = completedExercise.exerciseID?.uuidString ?? completedExercise.exerciseName
                
                for set in completedExercise.sets {
                    let currentBest = bestByExercise[key]?.set
                    
                    if currentBest == nil || isBetter(set, than: currentBest!) {
                        bestByExercise[key] = (name: completedExercise.exerciseName, set: set)
                    }
                }
            }
        }
        return bestByExercise
            .map { (exercise: $0.value.name, weight: $0.value.set.weight, reps: $0.value.set.reps) }
            .sorted { $0.exercise < $1.exercise }
    }
    
    private func isBetter(_ newSet: LoggedSet, than oldSet: LoggedSet) -> Bool {
        if newSet.weight > oldSet.weight { return true }
        if newSet.weight == oldSet.weight && newSet.reps > oldSet.reps { return true }
        return false
    }
    
}

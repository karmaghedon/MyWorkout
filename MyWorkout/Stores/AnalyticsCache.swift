import Combine
import Foundation

@MainActor
final class AnalyticsCache: ObservableObject {
    @Published private(set)
    var snapshot: AnalyticsSnapshot = .empty

    var recoveryWarnings: [RecoveryWarning] {
        snapshot.recoveryWarnings
    }

    var performanceWarnings: [ExercisePerformanceWarning] {
        snapshot.performanceWarnings
    }

    var totalSets: Int {
        snapshot.totalSets
    }

    var volumeByMuscleGroup: [MuscleGroupVolume] {
        snapshot.volumeByMuscleGroup
    }

    var personalRecords: [PersonalRecord] {
        snapshot.personalRecords
    }

    private let engine: AnalyticsEngine

    private var storeCancellable: AnyCancellable?
    private var recomputationTask: Task<Void, Never>?

    /// Identifies the newest requested analytics calculation.
    ///
    /// A result is published only when its generation still matches
    /// the latest request.
    private var recomputationGeneration = 0

    init(
        engine: AnalyticsEngine = AnalyticsEngine()
    ) {
        self.engine = engine
    }

    deinit {
        storeCancellable?.cancel()
        recomputationTask?.cancel()
    }

    // MARK: - Binding

    func bind(
        to logStore: WorkoutLogStore,
        templateStore: WorkoutTemplateStore
    ) {
        guard storeCancellable == nil else {
            return
        }

        storeCancellable = Publishers.CombineLatest(
            logStore.$logs,
            templateStore.$templates
        )
        .debounce(
            for: .milliseconds(300),
            scheduler: DispatchQueue.main
        )
        .sink { [weak self] logs, templates in
            self?.requestRecomputation(
                logs: logs,
                templates: templates
            )
        }
    }

    // MARK: - Recalculation

    private func requestRecomputation(
        logs: [WorkoutLog],
        templates: [WorkoutTemplate]
    ) {
        recomputationGeneration += 1
        let generation = recomputationGeneration

        recomputationTask?.cancel()

        /*
         This task currently inherits MainActor isolation.

         That is intentional for this step. The task boundary and stale-result
         protection are introduced first. The next phase will move the pure
         calculation to an AnalyticsWorker actor after its inputs are made
         safely transferable.
         */
        recomputationTask = Task { [weak self] in
            guard let self else {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            let registry = ExerciseRegistryFactory.make(
                templates: templates,
                logs: logs
            )

            guard !Task.isCancelled else {
                return
            }

            let newSnapshot = engine.makeSnapshot(
                logs: logs,
                registry: registry
            )

            guard !Task.isCancelled,
                  generation == recomputationGeneration else {
                return
            }

            snapshot = newSnapshot
        }
    }
}

import Foundation

@MainActor
protocol CustomExerciseReplacing {
    var persistenceError: StoreError? {
        get
    }

    @discardableResult
    func replaceAll(
        with exercises: [StoredCustomExercise]
    ) -> Bool
}

extension CustomExerciseStore:
    CustomExerciseReplacing {}

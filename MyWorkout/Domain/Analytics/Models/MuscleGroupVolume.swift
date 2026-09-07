import Foundation

struct MuscleGroupVolume: Identifiable, Equatable {
    let muscleGroup: MuscleGroup
    let setCount: Int

    var id: MuscleGroup {
        muscleGroup
    }
}

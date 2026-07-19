import Foundation

struct SeedData {

    static let exercises: [Exercise] = [
        exercise(
            "Bench Press",
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: """
            1. Lie on the bench with your eyes under the bar.
            2. Grip slightly wider than shoulder width.
            3. Pull shoulder blades back and down.
            4. Lower the bar under control to the lower chest.
            5. Press up without bouncing.
            """
        ),

        exercise(
            "Front Squat",
            muscleGroup: .legs,
            equipment: .barbell,
            instructions: """
            1. Place the bar across the front shoulders.
            2. Keep elbows high and chest tall.
            3. Brace before each rep.
            4. Squat down with knees tracking over toes.
            5. Drive through mid-foot to stand.
            """
        ),

        exercise(
            "Romanian Deadlift",
            muscleGroup: .hamstrings ,
            equipment: .barbell,
            instructions: """
            1. Stand tall with the bar in front of thighs.
            2. Keep knees slightly bent.
            3. Push hips backward while keeping back neutral.
            4. Lower until you feel hamstrings stretch.
            5. Drive hips forward to stand.
            """
        ),

        exercise(
            "Incline Bench Press",
            muscleGroup: .chest,
            equipment: .dumbbell,
            instructions: """
            1. Set bench to a low or moderate incline.
            2. Start with dumbbells at chest level.
            3. Keep shoulder blades pulled back.
            4. Press up under control.
            5. Lower slowly without shoulders rolling forward.
            """
        ),

        exercise(
            "Incline Row",
            muscleGroup: .back,
            equipment: .dumbbell,
            instructions: """
            1. Lie chest-down on an incline bench.
            2. Let dumbbells hang straight down.
            3. Pull elbows back toward hips.
            4. Squeeze shoulder blades.
            5. Lower slowly without shrugging.
            """
        ),

        exercise(
            "Bent Over Row - Underhand",
            muscleGroup: .back,
            equipment: .barbell,
            instructions: """
            1. Hold the bar with palms facing up.
            2. Hinge at hips with a neutral spine.
            3. Pull the bar toward lower ribs.
            4. Keep elbows close.
            5. Lower under control.
            """
        ),

        exercise(
            "Pull Up",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Grip bar with palms facing away.
            2. Start from a controlled hang.
            3. Pull shoulder blades down.
            4. Drive elbows toward ribs.
            5. Lower slowly without swinging.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Chin Up",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Grip bar with palms facing you.
            2. Start from a controlled hang.
            3. Pull elbows down toward sides.
            4. Bring chin above bar if possible.
            5. Lower slowly with control.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Chest Dip",
            muscleGroup: .chest,
            equipment: .bodyweight,
            instructions: """
            1. Support yourself on parallel bars.
            2. Keep shoulders down.
            3. Lean slightly forward.
            4. Lower under control.
            5. Press back up without bouncing.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Strict Military Press",
            muscleGroup: .shoulders,
            equipment: .barbell,
            instructions: """
            1. Start with bar at upper chest.
            2. Brace core and squeeze glutes.
            3. Press bar overhead.
            4. Move head slightly back, then through.
            5. Avoid leaning backward.
            """
        ),

        exercise(
            "Glute Bridge",
            muscleGroup: .glutes,
            equipment: .barbell,
            instructions: """
            1. Lie on back with knees bent.
            2. Place bar across hips if using weight.
            3. Drive through heels.
            4. Squeeze glutes at the top.
            5. Avoid over-arching lower back.
            """
        ),

        exercise(
            "Goblet Squat",
            muscleGroup: .legs,
            equipment: .kettlebellOrDumbbell,
            instructions: """
            1. Hold weight close to chest.
            2. Stand with feet about shoulder width.
            3. Brace core.
            4. Squat with knees tracking over toes.
            5. Stand through mid-foot.
            """
        ),

        exercise(
            "Inverted Row",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Set a bar around waist height.
            2. Lie underneath and grip the bar.
            3. Keep body straight.
            4. Pull chest toward bar.
            5. Lower slowly.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Face Pull",
            muscleGroup: .shoulders,
            equipment: .cableOrBand,
            instructions: """
            1. Set band or cable at face height.
            2. Pull toward your face.
            3. Keep elbows high.
            4. Squeeze rear delts and upper back.
            5. Return slowly.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Skullcrusher",
            muscleGroup: .triceps,
            equipment: .barbell,
            instructions: """
            1. Lie on bench with bar above chest.
            2. Keep upper arms mostly still.
            3. Bend elbows and lower bar carefully.
            4. Extend elbows to raise bar.
            5. Start light to protect elbows.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Triceps Extension",
            muscleGroup: .triceps,
            equipment: .barbell,
            instructions: """
            1. Hold bar with comfortable grip.
            2. Keep upper arms steady.
            3. Lower weight by bending elbows.
            4. Extend elbows under control.
            5. Avoid swinging.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Bicep Curl",
            muscleGroup: .biceps,
            equipment: .barbell,
            instructions: """
            1. Stand tall with palms facing up.
            2. Keep elbows close to sides.
            3. Curl without swinging.
            4. Lower slowly.
            5. Stop if elbow or forearm pain appears.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Hammer Curl",
            muscleGroup: .biceps,
            equipment: .dumbbell,
            instructions: """
            1. Hold dumbbells with palms facing each other.
            2. Keep elbows close.
            3. Curl without swinging.
            4. Lower slowly.
            5. Stop if forearm pain appears.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        )
    ]

    static let workouts: [Workout] = [
        Workout(name: "Workout A", exercises: workoutAExercises),
        Workout(name: "Workout B", exercises: workoutBExercises),
        Workout(name: "Workout C", exercises: workoutAExercises)
    ]

    static let defaultTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(name: "Workout A", exercises: workoutAExercises),
        WorkoutTemplate(name: "Workout B", exercises: workoutBExercises)
    ]

    private static var workoutAExercises: [Exercise] {
        exercisesFor([
            "Front Squat",
            "Bench Press",
            "Incline Row",
            "Chin Up",
            "Chest Dip",
            "Glute Bridge",
            "Skullcrusher",
            "Bicep Curl",
            "Face Pull"
        ])
    }

    private static var workoutBExercises: [Exercise] {
        exercisesFor([
            "Romanian Deadlift",
            "Front Squat",
            "Incline Bench Press",
            "Incline Row",
            "Pull Up",
            "Strict Military Press",
            "Triceps Extension",
            "Hammer Curl"
        ])
    }

    private static func exercisesFor(_ names: [String]) -> [Exercise] {
        names.compactMap { name in
            exercises.first { $0.name == name }
        }
    }

    private static func exercise(
        _ name: String,
        muscleGroup: MuscleGroup,
        equipment: ExerciseEquipment,
        instructions: String,

        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        difficulty: String = "Beginner",
        tips: [String] = [],
        commonMistakes: [String] = [],
        warnings: [String] = [],

        minReps: Int = 8,
        maxReps: Int = 10,
        increaseAmount: Double = 5,
        deloadAmount: Double = 5,
        stallLimit: Int = 3,
        exerciseType: ExerciseType = .compound,
        progressionStrategy: ProgressionStrategy = .doubleProgression
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            instructions: instructions,

            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            difficulty: difficulty,
            tips: tips,
            commonMistakes: commonMistakes,
            warnings: warnings,

            progressionRule: ProgressionRule(
                minReps: minReps,
                maxReps: maxReps,
                increaseAmount: increaseAmount,
                deloadAmount: deloadAmount,
                stallLimit: stallLimit
            ),
            exerciseType: exerciseType,
            progressionStrategy: progressionStrategy
        )
    }
}

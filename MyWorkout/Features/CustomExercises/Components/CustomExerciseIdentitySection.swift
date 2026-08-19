import SwiftUI

struct CustomExerciseIdentitySection: View {
    @Binding var draft: CustomExerciseDraft

    let muscleGroups: [MuscleGroup]
    let equipmentOptions: [ExerciseEquipment]
    let nameValidationMessage: String?

    var body: some View {
        Section {
            ValidatedNameField(
                title: "Exercise name",
                text: $draft.name
            )
            if let nameValidationMessage {
                Text(nameValidationMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.error)
                    .accessibilityLabel(
                        "Exercise name error: \(nameValidationMessage)"
                    )
            }
            Picker(
                "Muscle Group",
                selection: $draft.muscleGroup
            ) {
                ForEach(
                    muscleGroups,
                    id: \.self
                ) { muscleGroup in
                    Text(muscleGroup.displayName)
                        .tag(muscleGroup)
                }
            }

            Picker(
                "Equipment",
                selection: $draft.equipment
            ) {
                ForEach(
                    equipmentOptions,
                    id: \.self
                ) { equipment in
                    Text(equipment.displayName)
                        .tag(equipment)
                }
            }

            Picker(
                "Exercise Type",
                selection: $draft.exerciseType
            ) {
                ForEach(
                    ExerciseType.allCases,
                    id: \.self
                ) { exerciseType in
                    Text(exerciseType.displayName)
                        .tag(exerciseType)
                }
            }

            Picker(
                "Difficulty",
                selection: $draft.difficulty
            ) {
                ForEach(
                    difficultyOptions,
                    id: \.self
                ) { difficulty in
                    Text(difficulty)
                        .tag(difficulty)
                }
            }
        } header: {
            Text("Exercise")
        } footer: {
            Text(
                "Choose the primary category and equipment "
                + "used for this exercise."
            )
        }
        .onChange(of: draft.exerciseType) { _, newType in
            draft.progressionStrategy = recommendedStrategy(
                for: newType
            )
        }
    }

    private func recommendedStrategy(
        for exerciseType: ExerciseType
    ) -> ProgressionStrategy {
        switch exerciseType {
        case .compound:
            return .doubleProgression

        case .isolation:
            return .slowProgression

        case .bodyweight:
            return .bodyweightReps
        }
    }

    private var difficultyOptions: [String] {
        [
            "Beginner",
            "Intermediate",
            "Advanced"
        ]
    }
    
    
}

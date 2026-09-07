import Foundation

struct WorkoutCSVExporter {
    static func export(logs: [WorkoutLog], settings: UserSettings) -> String {
        var rows: [String] = []

        rows.append("Date,Workout,Exercise,Set,Weight,Unit,Reps,Notes")

        for log in logs {
            let date = log.date.formatted(date: .numeric, time: .shortened)

            for exercise in log.completedExercises {
                let escapedNotes = escape(exercise.notes)

                for set in exercise.sets {
                    let displayWeight = settings.displayWeight(set.weight)

                    rows.append([
                        escape(date),
                        escape(log.workoutName),
                        escape(exercise.exerciseName),
                        "\(set.setNumber)",
                        "\(formatWeight(displayWeight))",
                        settings.weightUnitLabel,
                        "\(set.reps)",
                        escapedNotes
                    ].joined(separator: ","))
                }
            }
        }

        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
    
    private static func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", value)
        : String(format: "%.1f", value)
    }
}

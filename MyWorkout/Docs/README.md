# MyWorkout Documentation

This directory is the internal reference for MyWorkout architecture, features, development practices, and release preparation.

## Recommended reading order

1. `Architecture/Architecture.md`
2. `Architecture/FolderStructure.md`
3. `Architecture/DataFlow.md`
4. `Architecture/Persistence.md`
5. `Architecture/BackupSystem.md`
6. `Architecture/TestingStrategy.md`
7. `Development/DevelopmentWorkflow.md`
8. `Development/CodingStandards.md`
9. `Development/DevelopmentRoadmap.md`
10. `Development/ReleaseChecklist.md`

## Architecture documents

- `Architecture.md` — system responsibilities and dependency direction
- `FolderStructure.md` — current folders and future organization rules
- `DataFlow.md` — state and event movement through the app
- `Persistence.md` — repositories, files, UserDefaults, migrations, and corruption protection
- `BackupSystem.md` — backup format, validation, import, and compatibility
- `TestingStrategy.md` — test boundaries and regression expectations

## Feature documents

- `ExerciseLibrary.md`
- `WorkoutSessions.md`
- `Templates.md`
- `Progression.md`
- `Analytics.md`
- `EquipmentInventory.md`
- `CustomExercises.md`
- `Recovery.md`
- `WeightTracking.md`
- `Nutrition.md`
- `WeeklyReport.md`
- `BodyProgress.md`

## Development documents

- `DevelopmentRoadmap.md`
- `DevelopmentWorkflow.md`
- `CodingStandards.md`
- `ReleaseChecklist.md`
- `WeightMacroTrainingRoadmap.md`

## Documentation rule

Code is the final source of runtime truth. These documents describe intended architecture and must be updated whenever a change alters responsibilities, persistence format, compatibility behavior, or development workflow.

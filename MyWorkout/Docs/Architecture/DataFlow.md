# Data Flow

## Application state flow

```text
User action
   ↓
SwiftUI view
   ↓
Store mutation method
   ↓
Validation / logic engine
   ↓
Published state update
   ↓
Persistence
   ↓
View refresh
```

Views should not write files or UserDefaults directly.

## Starting a workout

```text
StartWorkoutView
   ↓
Selected WorkoutTemplate
   ↓
Workout creation
   ↓
ActiveWorkoutStore.start
   ↓
ActiveWorkoutSnapshot persisted
   ↓
WorkoutSessionView
```

The store prevents a second active workout from silently replacing the current session.

## Active workout session

```text
WorkoutSessionView
   ↓
ExerciseSessionState mutation
   ↓
ActiveWorkoutStore
   ├── logged sets
   ├── current set
   ├── notes
   └── rest timer
   ↓
Debounced snapshot save
```

Navigating away does not end the active workout.

## Finishing a workout

```text
Active workout state
   ↓
WorkoutSessionEngine / completion assembly
   ↓
WorkoutLog
   ↓
WorkoutLogStore.add
   ↓
History persistence
   ↓
ActiveWorkoutStore.finish
   ↓
Active snapshot deletion
```

## Template flow

```text
Built-in exercises + custom exercises
   ↓
ExerciseRegistry
   ↓
Template editor selection
   ↓
WorkoutTemplateStore
   ↓
Versioned JSON repository
```

When templates are loaded, exercise references are refreshed through the registry where appropriate.

## Exercise resolution

```text
BuiltInExerciseSource
CustomExerciseSource
TemplateExerciseSource
HistoricalExerciseReferenceSource
        ↓
ExerciseRegistry
        ↓
Feature lookup
```

This centralizes exercise identity and supports historical compatibility.

## Progression flow

```text
Previous logged performances
   ↓
WorkoutLogStore query
   ↓
ProgressionEngine
   ↓
Suggested starting set
```

Progression is deterministic and does not persist state independently.

## Warm-up flow

```text
Exercise
Working weight
Equipment inventory
Unit settings
   ↓
WarmupEngine
   ↓
WarmupSet values
   ↓
PlateCalculator when barbell loading applies
```

Stored workout weights remain in pounds; display conversion happens at UI boundaries.

## Analytics flow

```text
WorkoutLogStore
WorkoutTemplateStore
CustomExerciseStore
        ↓
AnalyticsCache binding
        ↓
AnalyticsInputFactory
        ↓
AnalyticsEngine and analyzers
        ↓
AnalyticsSnapshot
        ↓
AnalyticsView components
```

## Backup export

```text
Current store values
   ↓
AppBackup
   ↓
BackupDocument
   ↓
ISO-8601 JSON file
```

## Backup import

```text
Selected JSON file
   ↓
BackupImportHandler
   ↓
Decode AppBackup
   ↓
Version check
   ↓
Custom exercise validation
   ↓
Store replacement contracts
   ↓
Persistence by each store
```

Validation occurs before store replacement begins.

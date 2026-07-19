# Testing Strategy

## Goals

Tests protect the parts of MyWorkout that are most expensive to lose or silently corrupt:

- training calculations
- progression decisions
- workout-session behavior
- persisted user data
- migration compatibility
- backup import validation

## Test target

```text
MyWorkoutTests
```

## Test categories

### Deterministic logic

Covered engines and analyzers include:

- `ProgressionEngine`
- `WarmupEngine`
- `PlateCalculator`
- `WeightConversion`
- `WorkoutSessionEngine`
- `RestTimerRule`
- `AnalyticsEngine`
- `RecoveryAnalyzer`
- `VolumeSpikeAnalyzer`
- `PerformanceDeclineAnalyzer`
- `IntraWorkoutFatigueAnalyzer`

Tests should cover primary paths, boundary values, empty input, first-use behavior, and invalid input.

### Validation

Covered validators include:

- `InputValidation`
- `ExerciseNameValidator`
- `CustomExerciseImportValidator`

Name tests must cover normalization behavior such as:

- case
- whitespace
- diacritics
- POSIX-stable comparison
- archived custom exercise collisions
- built-in reserved names

### Store persistence

Regression suites cover:

- `WorkoutLogStore`
- `WorkoutTemplateStore`
- `ActiveWorkoutStore`
- `EquipmentInventoryStore`
- `UserSettingsStore`
- `CustomExerciseStore`

Store tests verify:

- initial state
- successful loading
- successful save
- replacement
- load failure
- save failure
- corruption protection
- error exposure
- recovery after a successful operation
- migration behavior where applicable

### Repository compatibility

Repository tests and store tests should protect:

- versioned envelopes
- legacy raw values
- UserDefaults migration
- unsupported schema behavior
- atomic file writing assumptions

### Backup

Backup tests should cover:

- `AppBackup` round trip
- ISO-8601 dates
- optional custom exercises
- malformed data
- unsupported backup version
- validation before replacement
- successful replacement of all stores
- replacement failure reporting
- export/import symmetry

## Test doubles

The test target uses:

- repository mocks
- persistence mocks
- narrow protocol mocks
- test factories
- isolated UserDefaults suites
- thread-safe callback storage where background queues are involved

## Main-actor tests

Stores that publish UI state are main-actor isolated. Their test classes or methods should also use `@MainActor`.

## Asynchronous persistence tests

When saves occur on background queues:

- use expectations or callbacks
- avoid arbitrary sleeps
- assert both persisted value and exposed error state
- wait for the actual save completion signal

## Test naming

Preferred format:

```text
test<Action><Condition><ExpectedResult>
```

Example:

```swift
testLegacySettingsAreLoadedAndMigrated()
```

## Regression rule

Every fixed persistence or deterministic-logic bug should receive a test when the behavior can be reproduced reliably.

## Phase 19 protection

Folder reorganization and dead-code cleanup must run the complete test suite after every small movement batch.

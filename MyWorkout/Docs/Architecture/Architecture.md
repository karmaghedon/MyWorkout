# MyWorkout Architecture

Version: 2.0  
Status: Living document

## Product vision

MyWorkout is intended to support five product roles:

1. workout logger
2. progression engine
3. exercise encyclopedia
4. personal trainer
5. analytics platform

New architecture should strengthen at least one of these roles without weakening maintainability.

## Architectural goals

- deterministic business logic
- thin SwiftUI views
- reusable UI components
- explicit state ownership
- persistence that protects user data
- backward-compatible model evolution
- testable dependencies
- small, safe implementation steps

## Runtime composition

`MyWorkoutApp` owns the application-level stores:

```text
MyWorkoutApp
 ├── WorkoutLogStore
 ├── WorkoutTemplateStore
 ├── EquipmentInventoryStore
 ├── UserSettingsStore
 ├── ActiveWorkoutStore
 ├── CustomExerciseStore
 └── AnalyticsCache
```

These stores are injected into the SwiftUI hierarchy as environment objects.

## Main layers

### Views

Views render state and send user intent to stores or logic engines.

Responsibilities:

- layout
- navigation
- form binding
- user interaction
- presentation of errors and empty states

Views should not own persistence or complex training calculations.

### Components

Reusable SwiftUI components live beside their owning feature under `Features/<Feature>/Components`. Components shared by multiple features live under `Features/Shared/Components`.

Examples:

- form controls
- inventory rows
- workout-session cards
- analytics sections
- feedback and error views
- exercise education sections

A screen should assemble these components rather than duplicate their implementation.

### Stores

Stores are `ObservableObject` state owners.

Responsibilities:

- application-facing state
- mutation APIs
- persistence coordination
- error exposure
- calls into deterministic logic
- synchronization between persisted data and views

Stores are main-actor isolated where UI-observed state is involved.

### Models

Models represent product concepts rather than individual screens.

Examples:

- `Exercise`
- `Workout`
- `WorkoutLog`
- `WorkoutTemplate`
- `ExerciseSessionState`
- `StoredCustomExercise`
- `EquipmentInventory`
- `UserSettings`
- `AppBackup`

Persisted models are Codable and evolve through backward-compatible decoding or explicit schema envelopes.

### Logic

The `Logic` layer contains deterministic training and analysis behavior.

Examples:

- `ProgressionEngine`
- `WarmupEngine`
- `PlateCalculator`
- `WeightConversion`
- `WorkoutSessionEngine`
- `RecoveryAnalyzer`
- `VolumeSpikeAnalyzer`
- `PerformanceDeclineAnalyzer`
- `IntraWorkoutFatigueAnalyzer`
- `AnalyticsEngine`

Logic should avoid SwiftUI, file access, UserDefaults, and mutable global state.

### Repositories

Repositories isolate file persistence for larger collections.

Current repository-backed domains:

- workout logs
- workout templates
- custom exercises

Repositories support dependency injection, test doubles, migration, schema validation, and atomic file writes.

### Persistence

Persistence implementation is split between:

- repository-backed Application Support JSON files
- active-workout snapshot persistence
- UserDefaults-backed settings and equipment
- JSON backup documents
- CSV export

See `Persistence.md`.

### Protocols

Narrow protocols define only the capabilities required by a consumer.

Examples include repository interfaces and backup replacement interfaces.

Protocols should not mirror every method on a concrete type. They should expose the minimum dependency contract.

## Dependency direction

Preferred direction:

```text
Views
  ↓
Stores
  ↓
Logic / Domain Models
  ↓
Repositories / Persistence
```

Logic must not depend on views or stores.

Repositories must not depend on SwiftUI.

Models should not depend on concrete stores.

## Exercise resolution

Exercise identity can originate from multiple sources:

- built-in seed data
- custom exercises
- template references
- historical workout references

`ExerciseRegistry` provides a centralized lookup path and prevents feature-specific lookup logic from spreading through the UI.

## Analytics

`AnalyticsCache` observes relevant stores and creates cached analytics snapshots. Heavy analytics calculations are kept outside views.

## Error handling

Persistence errors must be surfaced through store state.

User data failures must never be handled only by `print()`.

The UI uses store error banners to present actionable failures.

## Concurrency

- UI-observed stores are main-actor isolated.
- File saves may use background queues.
- Mutable store collections are captured as immutable snapshots before background work.
- Completion and error state return to the main actor.

## Future direction

Phase 19 may reorganize folders into clearer feature and core boundaries. Folder movement must not change behavior and should be protected by the Phase 17 test baseline.

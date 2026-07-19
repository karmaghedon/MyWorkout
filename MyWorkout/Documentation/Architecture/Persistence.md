# Persistence

Persistence is designed around three goals:

1. protect user data
2. support backward compatibility
3. make behavior testable

## Persistence map

| Domain | Storage | Abstraction |
|---|---|---|
| Workout history | Application Support JSON | `WorkoutLogRepository` |
| Workout templates | Application Support JSON | `WorkoutTemplateRepository` |
| Custom exercises | Application Support JSON | `CustomExerciseRepository` |
| Active workout | Application Support snapshot | `ActiveWorkoutPersisting` |
| Equipment inventory | UserDefaults | injectable `UserDefaults` |
| User settings | UserDefaults | injectable `UserDefaults` |
| Backup | user-selected JSON document | `AppBackup` and `BackupDocument` |
| Workout export | CSV document | CSV exporter/document |

## Versioned envelopes

Persistent collections use:

```swift
PersistedEnvelope(
    schemaVersion: Int,
    payload: Payload
)
```

The envelope separates storage version from domain model details.

Repositories reject unsupported schema versions rather than guessing.

## Atomic writes

File repositories use:

```swift
data.write(to: fileURL, options: .atomic)
```

Atomic writing reduces the chance of leaving a partially written JSON file after interruption.

## Application Support

Large or growing collections are stored under:

```text
Application Support/MyWorkout/
```

Known files include:

- workout logs
- workout templates
- custom exercises
- active workout snapshot

## Legacy migration

### Workout logs and templates

Repositories support migration from older UserDefaults data.

Migration order:

1. decode legacy value
2. write the new versioned file
3. remove the legacy UserDefaults value only after the file save succeeds

### Legacy unwrapped files

Where supported, repositories attempt:

1. versioned envelope decoding
2. legacy raw-array decoding
3. rewrite into the current envelope format

### User settings

`UserSettingsStore` supports the original unwrapped `UserSettings` value and migrates it into the current envelope.

`UserSettings` also supplies defaults for fields missing from older payloads.

## Corruption protection

Stores that cannot read persisted data must avoid automatically overwriting that data.

The standard behavior is:

```text
load fails
   ↓
show safe in-memory fallback where appropriate
   ↓
mark persistence non-writable
   ↓
surface loading error
   ↓
block automatic overwrite
```

This is used for history, templates, and settings where preserving unreadable data is safer than replacing it.

## Error exposure

Persistence-capable stores expose:

```swift
@Published private(set) var persistenceError: StoreError?
```

The UI may present these through `StoreErrorBanner`.

A persistence failure must not be handled only by console output.

## Background saves

Stores that save on background queues first capture an immutable snapshot on the main actor.

```text
Main actor collection
   ↓ copy
Immutable snapshot
   ↓
Background repository save
   ↓
Main actor error update
```

This avoids reading mutable published state from a background queue.

## Active workout persistence

The active workout is stored as an explicit snapshot rather than attempting to encode the store itself.

The snapshot includes:

- active workout
- exercise session states
- workout start time
- persisted rest-timer state
- schema version where applicable

Active persistence is debounced so frequent session edits do not produce unnecessary writes.

## UserDefaults injection

`EquipmentInventoryStore` and `UserSettingsStore` accept injectable UserDefaults and persistence keys.

Production defaults preserve existing behavior:

```swift
userDefaults: .standard
```

Tests use isolated suites.

## Persistence change checklist

Before changing a persisted type:

1. identify all stored formats
2. preserve existing decoding
3. decide whether a schema version changes
4. add migration only when required
5. ensure failed migration leaves original data intact
6. add regression tests
7. verify backup import/export compatibility
8. verify fresh install behavior
9. verify upgrade behavior

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

### A hazard in the envelope/legacy fallback, and why it's settings-specific

The envelope/legacy dual-decode described above (`try?` the versioned envelope,
fall back to the legacy shape on failure) has a sharp edge: `try?` treats
*every* envelope-decode failure the same way, whether the data isn't an
envelope at all or whether it *is* an envelope whose payload merely has one
corrupted or unrecognized field. `UserSettingsStore` hit this in practice —
a `UserSettings` payload with, say, an unrecognized `appearanceMode` value
failed the envelope decode, fell through to the legacy path, and because
every field of `UserSettings.init(from:)` is `decodeIfPresent(...) ??
defaults`, the legacy decoder "succeeded" against the mismatched
envelope-shaped JSON — silently producing an all-defaults `UserSettings`
that then overwrote the real persisted data via the migration-triggered
save. This is the corruption-protection contract failing at exactly the
point it exists to guard.

The fix, in `UserSettingsStore.decodeSettings`: check whether the data is
shaped like an envelope (top-level `schemaVersion` and `payload` keys, via
`JSONSerialization`) *before* choosing a decode path, rather than inferring
the path from whether the envelope decode happened to throw. Only data with
no envelope keys at all falls to the legacy path now; envelope-shaped data
with a bad payload field throws a real error, which the caller already
handles correctly (preserve on-disk data, mark non-writable, surface the
error).

This exact vulnerability is specific to how `UserSettings` decodes — a
struct where every field independently defaults via `decodeIfPresent(...) ??
defaults`, so a shape mismatch can decode "successfully" into an
unintentional all-defaults value. The other repositories using the same
envelope/legacy dual-decode pattern (`FileWorkoutLogRepository`,
`FileWorkoutTemplateRepository`, `FileCustomExerciseRepository`) were
checked and don't share it: their legacy fallback target is a plain
`Array` (`[WorkoutLog]`, `[WorkoutTemplate]`, `[StoredCustomExercise]`),
and JSONDecoder cannot decode a JSON object (the envelope shape) as an
array type at all — a corrupted payload there throws a real `DecodingError`
from the legacy attempt too, correctly hitting the corruption-protection
path rather than silently succeeding. `EquipmentInventoryStore` doesn't use
this pattern at all — a single direct `JSONDecoder().decode` with no
envelope/legacy fallback.

The general lesson for future persisted types: this hazard reappears
whenever a legacy/fallback decode target has every field defaulted
independently (the way `UserSettings` does). If a future payload type
adopts that same fully-optional-with-defaults shape for its legacy decode
target, it needs the same explicit shape check `UserSettingsStore` uses,
not just a bare `try?`.

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

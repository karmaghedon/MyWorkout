# Backup System

## Purpose

The backup system provides a portable JSON representation of user-owned application data.

## Backup payload

`AppBackup` currently contains:

- backup version
- export timestamp
- workout logs
- workout templates
- equipment inventory
- user settings
- custom exercises
- body measurement logs (neck circumference only — see below)
- macro goals (calorie/macro target history)
- daily nutrition logs (one calorie/macro record per day; macros also
  live in HealthKit — see below)

Current backup version:

```swift
AppBackup.currentVersion == 5
```

HealthKit-resident data (weight, body fat %, waist circumference,
nutrition) is deliberately **not** part of this backup — it already
lives in HealthKit and syncs via iCloud independently of this app's own
JSON export. `bodyMeasurementLogs` exists solely for neck
circumference, the one body-metrics field HealthKit has no quantity
type for.

## Backward compatibility

`customExercises`, `bodyMeasurementLogs`, `macroGoals`, and
`dailyNutritionLogs` all decode with an empty-array fallback. This
allows older backups that predate any of these fields to remain
readable.

```text
missing customExercises / bodyMeasurementLogs / macroGoals / dailyNutritionLogs
   ↓
[]
```

## Export

`BackupDocument` conforms to `FileDocument`.

Export behavior:

- JSON
- pretty printed
- sorted keys
- ISO-8601 date encoding

## Import flow

`BackupImportHandler` performs:

1. security-scoped file access
2. file reading
3. ISO-8601 decoding
4. `AppBackup` decoding
5. backup-version validation
6. custom exercise validation
7. store replacement
8. result reporting

## Version handling

Backups newer than the app supports return:

```swift
.unsupportedVersion(version)
```

Older supported backups may be decoded through model-level compatibility rules.

The importer must never silently interpret an unknown future schema.

## Validation before replacement

Custom exercises are validated before any store is modified.

Validation checks should continue to include:

- valid names
- duplicate names
- collision with reserved built-in exercises
- model validity
- normalization rules

## Replacement interfaces

The importer depends on narrow replacement capabilities:

- `WorkoutLogReplacing`
- `WorkoutTemplateReplacing`
- `EquipmentReplacing`
- `SettingsReplacing`
- `CustomExerciseReplacing`
- `BodyMeasurementLogReplacing`
- `MacroGoalReplacing`
- `DailyNutritionLogReplacing`

This makes the import coordinator testable without constructing real persistence stores.

## Import ordering

Current replacement order:

1. workout logs
2. workout templates
3. equipment
4. settings
5. custom exercises
6. body measurement logs
7. macro goals
8. daily nutrition logs

The order is part of current behavior and should be covered by regression tests if dependency assumptions develop.

## Atomicity limitation

Validation is atomic, but multi-store replacement is not a single database transaction.

Each store persists independently. A failure in a later store may occur after earlier stores have already been replaced.

For version 1.0, this limitation must be documented and tested. A future transactional restore coordinator may stage all files and commit them together if product risk justifies the added complexity.

## Security-scoped access

Imported files may originate outside the app sandbox. The importer begins security-scoped access and stops it in `defer` when access was granted.

## Backup compatibility policy

A release must verify:

- current backup exports successfully
- current backup imports successfully
- version 1 backup imports where expected
- missing optional fields use safe defaults
- unsupported future versions are rejected
- invalid custom exercise data is rejected before replacement
- corrupted JSON does not mutate stores

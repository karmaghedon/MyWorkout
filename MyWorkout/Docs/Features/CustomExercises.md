# Custom Exercises

## Purpose

Custom exercises allow users to extend the exercise library while preserving consistent validation, identity, templates, backup, and historical behavior.

## Main types

- `StoredCustomExercise`
- `CustomExerciseDraft`
- `CustomExerciseStore`
- `CustomExerciseRepository`
- `FileCustomExerciseRepository`
- `ExerciseNameValidator`
- `CustomExerciseImportValidator`

## Capabilities

- create
- edit
- archive
- delete where safe
- restore through backup
- include in template selection
- participate in exercise registry lookup

## Name validation

`ExerciseNameValidator` is the single source of truth.

Normalization accounts for:

- case
- surrounding and repeated whitespace
- diacritics
- POSIX-stable comparison

Duplicate checking includes:

- built-in exercises
- active custom exercises
- archived custom exercises

## Referential safety

Deletion or archival must consider references from:

- templates
- workout history
- active workouts where applicable

Historical records must remain readable even when the current custom exercise changes.

## Persistence

Custom exercises are stored in a versioned Application Support JSON file using atomic writes.

## Import validation

Backup import validates the complete custom exercise collection before store replacement.

## Regression focus

- store CRUD behavior
- validation
- duplicate names
- archived-name collisions
- replacement
- failed persistence
- import validation

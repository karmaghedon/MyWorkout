# Workout Templates

## Purpose

Templates define reusable exercise sequences for starting workouts.

## Main types

- `WorkoutTemplate`
- `WorkoutTemplateStore`
- `WorkoutTemplateRepository`
- `FileWorkoutTemplateRepository`

## Main views

- `TemplatesView`
- `CreateWorkoutTemplateView`
- `TemplateEditorView`
- `TemplateExercisesSection` — shared "selected exercises" list (sets/weight
  steppers, reorder, delete, superset grouping) used by both of the above
- `TemplateExercisePickerView` — equipment- and name-searchable exercise
  picker used by `TemplateEditorView`'s "Add Exercises"
- `StartWorkoutView`

## Capabilities

- create
- edit
- delete
- duplicate
- add exercises
- remove exercises
- filter exercise selection by equipment
- search exercise selection by name
- validate template names
- restore default templates on first launch
- configure a per-exercise working-set count (`Exercise.targetSets`)
- configure a per-exercise starting weight (`Exercise.targetWeightPounds`),
  used only the first time that exercise is performed — real progression
  history takes over after that
- group 2+ exercises into a superset/circuit (`Exercise.supersetGroupID`)
  so they rest only after the group's last member, not after every
  exercise

## Exercise refresh

Loaded or imported templates are refreshed through an exercise registry so built-in exercise definitions can evolve without duplicating lookup behavior throughout the UI.

Refresh preserves the three per-template override fields
(`targetSets`, `targetWeightPounds`, `supersetGroupID`) from the saved
exercise rather than replacing it wholesale with the freshly-resolved
built-in definition — that definition always carries the *global*
defaults for those fields, so a naive swap silently discarded whatever
had actually been configured for the template on every save. Any new
per-template override field added in the future needs the same explicit
carry-over.

## Starting weight sync

After every finished workout, `WorkoutTemplateStore.syncStartingWeights(from:)`
updates each matching template's per-exercise `targetWeightPounds` to
the last set actually logged for that exercise. This only keeps the
*displayed* template value honest — it has no effect on what weight a
session actually starts at once real history exists, since progression
already drives that. Templates are matched by
`WorkoutLog.workoutName == template.name` (same approach Home's "Next
Workout" card uses, with the same renaming caveat); exercises within a
matched template are matched by id, falling back to normalized name.

## Persistence

Templates are stored in a versioned JSON envelope in Application Support.

Legacy UserDefaults and legacy unwrapped file formats are migrated where supported.

Unreadable persisted templates are not automatically overwritten.

## Duplicate naming

Template duplication produces:

```text
Original Copy
Original Copy 2
Original Copy 3
```

## Regression focus

- first-launch defaults
- load and migration
- add/update/delete
- duplicate naming
- replace-all
- exercise refresh (including that per-template overrides survive it)
- persistence failure protection
- starting-weight sync from a finished workout

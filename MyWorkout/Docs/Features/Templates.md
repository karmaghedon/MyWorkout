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
- configure a per-exercise progression rep range
  (`Exercise.progressionRule.minReps`/`maxReps`) so the weight-increase
  suggestion matches how that exercise is actually trained (e.g.
  straight sets of 8) instead of always assuming the global default
- toggle `Exercise.progressionEnabled` per exercise ("Auto Progression")
  to turn automatic weight increase/deload suggestions off entirely for
  that exercise — the working weight then just carries forward
  unchanged between sessions (still manually adjustable in the session
  UI itself), with no suggestion banner shown
- toggle a fixed, manually-edited warm-up ramp per exercise ("Auto
  Warm-up" off) via `Exercise.customWarmups`, with a live preview of the
  auto-calculated ramp shown whenever it's left on

## Exercise refresh

Loaded or imported templates are refreshed through an exercise registry so built-in exercise definitions can evolve without duplicating lookup behavior throughout the UI.

Refresh preserves the per-template override fields
(`targetSets`, `targetWeightPounds`, `supersetGroupID`,
`progressionRule`, `progressionEnabled`, `customWarmups`) from the
saved exercise rather than replacing it wholesale with the
freshly-resolved built-in definition — that definition always carries
the *global* defaults for those fields, so a naive swap silently
discarded whatever had actually been configured for the template on
every save. Any new per-template override field added in the future
needs the same explicit carry-over.

## Per-exercise progression and warm-up overrides

Each exercise row in `TemplateExercisesSection` carries two independent
toggles, alongside the existing sets/weight/rep-range controls:

- **Auto Progression** (`Exercise.progressionEnabled`, default `true`)
  — when turned off, `WorkoutSessionEngine.initialState` skips
  `ProgressionEngine.suggestion` entirely for that exercise and just
  carries the last logged weight and rep count forward unchanged, with
  no suggestion message. This is for exercises where the user wants to
  stay in full manual control of the load (e.g. technique-sensitive
  lifts, or ones already at a deliberately-fixed working weight).

- **Auto Warm-up** (`Exercise.customWarmups`, default `nil`) — while on,
  the row shows a live read-only preview of
  `WarmupEngine.generateWarmups(...)` computed off the exercise's
  current working weight, updating immediately as that weight changes.
  Turning it off seeds `customWarmups` from that same auto-calculation
  as a starting point, then switches the row to an editable list
  (weight/reps steppers per set, delete, and an "Add Warm-up Set"
  button that seeds a new row from the last one) so the fixed ramp can
  be hand-tuned and saved with the template. Turning it back on
  discards the fixed list (`customWarmups = nil`) and reverts to
  always-current auto-calculation — the fixed list is not preserved for
  next time.

At session time, `WarmupEngine.resolveWarmups` resolves the warm-up
ramp with three-tier precedence: a session-time edit
(`ExerciseSessionState.customWarmups`, made via the Checklist layout's
edit flow) always wins for that one workout, then the template's
`Exercise.customWarmups` fixed list, then auto-calculation. This lets a
template define a sensible default ramp while still allowing one-off
adjustments mid-workout without changing the template.

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
- exercise refresh (including that all four per-template overrides
  survive it)
- persistence failure protection
- starting-weight sync from a finished workout

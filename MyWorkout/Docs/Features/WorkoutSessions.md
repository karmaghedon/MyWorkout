# Workout Sessions

## Purpose

The workout-session feature manages an in-progress workout safely across navigation and app lifecycle interruptions.

## Main responsibilities

- start a workout
- prevent accidental active-session replacement
- track elapsed time
- log sets
- display previous performance
- generate warm-ups
- run rest timers, suppressed between superset members (see below)
- capture exercise notes
- finish or cancel
- persist and restore active state

## Main types

- `ActiveWorkoutStore`
- `Workout`
- `ExerciseSessionState`
- `RestTimerState`
- `WorkoutSessionEngine`
- `ActiveWorkoutSnapshot`
- `ActiveWorkoutPersisting`
- `WorkoutSessionLayout` — Classic or Checklist, a user setting

## Layout

Two interchangeable presentations of the same exercise/set data, chosen
in Settings → Workout Session (default: Classic):

- **Classic** — `ExerciseSessionCardView`, always-visible weight/reps
  steppers (`CurrentSetCardView`).
- **Checklist** — `ChecklistExerciseSessionCardView`, warm-up and
  working sets as tappable `SetChecklistRow`s; the next working set can
  be tapped (pencil icon) to reveal an inline weight/reps editor before
  logging.

Both read from and write to the same `ExerciseSessionState`, so
switching layouts mid-workout loses nothing.

## Supersets

Exercises sharing a template-configured `Exercise.supersetGroupID` are
meant to be performed back-to-back with no rest between them, resting
only once the group's last member (by the workout's exercise order)
logs a set. `WorkoutSessionEngine.shouldStartRest(after:in:)` decides
this per set logged — ungrouped exercises always start rest, unchanged.
Session cards for grouped exercises render a colored leading bar so the
grouping is visible while actually working out, matching the same
treatment shown when building the template.

## UI composition

`WorkoutSessionView` assembles reusable session components including:

- pinned workout timer (`CompactWorkoutTimerBar`)
- exercise list (`WorkoutExerciseListView`, branches per exercise on
  `WorkoutSessionLayout` and applies the superset leading-bar indicator)
- session card (Classic or Checklist, see above)
- current set card / checklist rows
- warm-up section
- previous performance
- logged sets
- notes
- action controls
- dialogs

## Persistence behavior

The active workout persists independently from workout history.

Navigation away from the session must not reset:

- workout start time
- elapsed duration
- logged sets
- notes
- rest timer

## Starting another workout

When an active workout exists, a new workout must not silently overwrite it.

The start flow should return an explicit result that allows the UI to resume the existing session or present an appropriate restriction.

## Finish behavior

Finishing creates a `WorkoutLog`, saves it through `WorkoutLogStore`, and clears active persistence.

## Cancel behavior

Canceling clears current session state and removes the persisted active snapshot.

## Regression focus

- start
- second-start prevention
- restore
- duration
- rest timer, including that it's suppressed between superset members
  and only starts for the group's last exercise
- set state
- cancel
- finish
- persistence failure
- delete failure
- Classic/Checklist layout switch mid-workout

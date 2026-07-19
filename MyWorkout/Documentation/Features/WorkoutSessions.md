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
- run rest timers
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

## UI composition

`WorkoutSessionView` assembles reusable session components including:

- workout timer
- exercise list
- session card
- current set card
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
- rest timer
- set state
- cancel
- finish
- persistence failure
- delete failure

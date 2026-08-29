# MyWorkout F1.5 — Stateful Workout Destination

## Add

- `MyWorkout/App/Navigation/WorkoutTabPresentation.swift`

## Replace

- `MyWorkout/App/Navigation/MyWorkoutTabBar.swift`
- `MyWorkout/App/Navigation/AppShellView.swift`

## No changes required

- `ActiveWorkoutStore.swift`
- `RestTimerState.swift`
- `StartWorkoutView.swift`
- `WorkoutSessionView.swift`

The existing store already provides the required source-of-truth APIs and already prevents accidental workout replacement.

## Behavior

### No active workout

- Center destination displays `Workout`.
- Selecting it opens the Workout root.

### Active workout

- Center destination displays `Resume`.
- Selecting it routes directly to `.activeWorkout`.
- Existing workout state is preserved.

### Active rest timer

- Center destination displays `Resume`.
- Remaining rest time appears below it using a compact monospaced value.
- VoiceOver announces the remaining rest time.

## Ownership

- `ActiveWorkoutStore` owns workout and timer state.
- `WorkoutTabPresentation` converts state into display metadata.
- `MyWorkoutTabBar` renders the supplied presentation.
- `AppShellView` owns tab selection and navigation reactions.

## Validation

1. Launch with no active workout: center label is `Workout`.
2. Start a workout: center label becomes `Resume`.
3. Leave the Workout tab and tap Resume: active session opens directly.
4. Log a set: rest countdown appears in the tab bar.
5. Let rest expire: countdown disappears while Resume remains.
6. Switch between all tabs: active workout remains intact.
7. Tap another template while active: the existing warning still prevents silent replacement.
8. Finish workout: center label returns to `Workout`.
9. Cancel workout: center label returns to `Workout`.
10. Restore an active workout after relaunch: center destination shows Resume.

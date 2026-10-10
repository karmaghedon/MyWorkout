# Analytics

## Purpose

Analytics turns workout history into useful training feedback without placing calculations in SwiftUI views.

## Main types

- `AnalyticsCache`
- `AnalyticsInputFactory`
- `AnalyticsEngine`
- `AnalyticsInput`
- `AnalyticsSnapshot`
- `MuscleGroupVolume`
- `PersonalRecord`
- `ExercisePerformanceAnalyzer`

## Inputs

Analytics may use:

- workout logs
- templates
- custom exercises
- exercise registry information

## Outputs

Current presentation includes:

- overview
- recent workouts
- volume by muscle group
- personal records
- performance warnings
- recovery warnings
- strength trends

## Cache

`AnalyticsCache` binds to relevant stores and produces reusable analytics state for the UI.

Views should consume snapshots rather than recalculate analytics in `body`.

## UI components

- `AnalyticsOverviewSection`
- `RecentWorkoutsSection`
- `VolumeByMuscleGroupSection`
- `PersonalRecordsSection`
- `PerformanceWarningsSection`
- `RecoveryWarningsSection`

## Segmented layout

`AnalyticsView` used to stack all six section components above plus
`ConsistencySection` in one long `List` — overwhelming, and several
sections (Personal Records, Volume by Muscle Group, both warnings
sections) rendered an empty placeholder ("No PRs yet", etc.) even when
there was nothing to say. It's now a segmented `Picker` over four tabs,
each grouping sections that answer the same kind of question:

- **Overview** — `AnalyticsOverviewSection` + `ConsistencySection`
- **Volume** — `VolumeByMuscleGroupSection` + `VolumeTrendSection`
- **Records** — `PersonalRecordsSection` + `RecentWorkoutsSection`
- **Alerts** — `RecoveryWarningsSection` + `PerformanceWarningsSection`,
  collapsed into one combined "Nothing needs your attention right now"
  message instead of two separate empty-state sections when both are
  empty. The tab's own label gets a live count appended (e.g. "Alerts
  (3)") whenever there's something to flag, so it's visible without
  switching tabs first.

Only one tab's sections mount at a time — switching tabs is a `List`
content swap behind the same `Picker`, not a navigation push.

## Strength trends

`StrengthTrendView` (reached from `ProgressHubView`'s "Strength" row,
`AppRoute.strengthTrends`) plots estimated 1RM over time for one
exercise at a time, picked from a menu. That picker used to list every
exercise that had ever appeared in `logStore.logs` — which drifts
toward "every exercise in the library" the longer the app's been used,
since a one-off test log or an exercise from a since-deleted template
never ages back out. It now sources the picker from
`templateStore.templates` instead, so it only ever lists exercises
actually assigned to a *current* template — what you're training now,
not everything you've ever logged a single set of.

## Testing

Analytics logic is deterministic and covered independently from SwiftUI.

## Future extensions

- date-range filters
- exercise-specific trend charts
- estimated one-rep-max history
- training-frequency analysis
- volume landmarks
- plateau detection

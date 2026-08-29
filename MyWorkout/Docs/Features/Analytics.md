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

## Testing

Analytics logic is deterministic and covered independently from SwiftUI.

## Future extensions

- date-range filters
- exercise-specific trend charts
- estimated one-rep-max history
- training-frequency analysis
- volume landmarks
- plateau detection

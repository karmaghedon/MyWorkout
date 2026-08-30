# Weight Tracking

## Purpose

Lets the user log a weigh-in — weight, and optionally body fat %, waist,
and neck — as the foundation for the broader weight/calorie/macro
tracking feature set. Weight, body fat %, and waist are written directly
to HealthKit so they sync across devices via iCloud and show up in the
Health app / Apple Watch with no extra work. Neck circumference has no
HealthKit quantity type, so it's the one field stored locally.

## Main types

- `HealthKitTypeCatalog` — the full set of HealthKit types this app
  reads or writes, requested together in one authorization call so the
  user only ever sees one permission sheet across every phase of this
  feature, not one per screen.
- `HealthKitAuthorizationManager` — thin `HKHealthStore` authorization
  wrapper.
- `BodyMetricsHealthKitServicing` (protocol) / `BodyMetricsHealthKitService`
  (concrete) — writes weight/body fat %/waist to HealthKit.
- `BodyMeasurementLog` — local-only neck measurement record.
- `BodyMeasurementLogRepository` (protocol) / `FileBodyMeasurementLogRepository`
  — file-backed JSON persistence, same `PersistedEnvelope` pattern as
  every other domain in this app.
- `BodyMeasurementLogStore` — `@MainActor ObservableObject`, mirrors
  `WorkoutLogStore` exactly (persistence-error surfacing, background
  save queue, `isPersistenceWritable` guard).

## HealthKit integration

Weight is required; body fat % and waist are optional per weigh-in.
`BodyMetricsHealthKitServicing.logWeight(kg:bodyFatPercent:waistCm:date:)`
writes each provided value as its own `HKQuantitySample` at the same
timestamp. Body fat % is converted from the UI's 0–100 scale to
HealthKit's expected 0–1 fraction at the write boundary — nowhere else
in the app deals with that unit.

Weight respects `UserSettings.unitSystem` (lb/kg) exactly like the rest
of the app, converted to HealthKit's required kilograms via
`WeightConversion` at the save boundary. Waist and neck are entered and
stored in centimeters only for now — this app has no existing
length-unit system to hook into (only weight has an lb/kg toggle);
supporting inches is a future extension, not a v1 gap that blocks
anything.

## Local persistence

`BodyMeasurementLog` (id, date, neckCm) is the only model this feature
persists outside HealthKit. It follows the app's standard Tier-2
pattern: `~/Library/Application Support/MyWorkout/body_measurement_logs.json`,
wrapped in `PersistedEnvelope`, schema version 1. Included in
`AppBackup` (bumped to version 3) via a `BodyMeasurementLogReplacing`
conformance, appended to `BackupImportHandler`'s replacement order.
HealthKit-resident data (weight, body fat %, waist) is deliberately
*not* part of the JSON backup — it already lives in HealthKit/iCloud.

## UI

`LogWeightView` — a form with toggle-gated body fat %/waist/neck fields
alongside the always-shown weight field. Requests HealthKit
authorization on first appearance if not yet granted, and shows an
inline warning (routing the user to Settings) if access was denied.
Reached from Home (`DashboardView`) via a "Log Weight" quick action and
the `AppRoute.logWeight` route. Dismisses the keyboard on a tap
anywhere else on screen via the existing `dismissKeyboardOnTap()`
utility (`Core/Utilities/Keyboard.swift`), same as the workout session
and equipment screens.

Each numeric field is a `NumericEntryField` — a small view private to
`LogWeightView.swift` — rather than the workout session's
`DoubleBigStepperControl`/`BigStepperControl`. Those two are shared with
the workout session screens, where +/- stepper buttons are a deliberate,
already-tuned part of that UI; body-metrics entry deliberately has no
+/- buttons, just a directly-tappable number-pad field (reported as
wanted after the first on-device pass). `NumericEntryField` still reuses
the underlying `NumericPadTextField` (cursor pinned to the end
regardless of tap position) and the same "resync only actually changes
the field when the parsed value changes" idiom `ChecklistExerciseSessionCardView`'s
next-set fields use, which is what keeps typing a decimal (e.g. "72.5")
from getting reverted mid-keystroke.

## Testing

`BodyMeasurementLogStoreTests` covers load/save/replaceAll against
`MockBodyMeasurementLogRepository` — never the real file-backed
repository. **Hard rule**: no test in this codebase may construct
`FileBodyMeasurementLogRepository()`'s default initializer or a real
`HKHealthStore`-backed service. `xcodebuild test` in this dev
environment runs against the connected physical iPhone (CoreSimulator
is broken here), so a test that touches real persistence or real
HealthKit can corrupt real production data or pop real permission
dialogs — this already happened once to this project's real template
data before this rule was written down.

## Future extensions

- Inches/cm toggle for waist and neck, matching the existing lb/kg
  toggle for weight.
- Editing or deleting a previously-logged neck measurement.
- Surfacing a "last weighed in" summary on Home ahead of the full
  Weekly Report / Progress chart phases.

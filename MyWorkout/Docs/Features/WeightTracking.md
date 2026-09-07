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

`LogWeightView` is weight-only — body fat % is never entered anywhere
in this app (always calculated, see `NavyBodyFatCalculator` below), and
waist/neck/hip moved to their own weekly screen (below) since they're
logged on a different cadence than daily weigh-ins. Requests HealthKit
authorization on first appearance if not yet granted, and shows an
inline warning (routing the user to Settings) if access was denied.
Reached from Home (`DashboardView`) via a "Log Weight" quick action and
the `AppRoute.logWeight` route, and also from `WeeklySummaryCard`'s
tappable day dots for a past date (pre-fills that day's existing
weight, if any, so re-opening it edits rather than always starting
blank). Dismisses the keyboard on a tap anywhere else on screen via the
existing `dismissKeyboardOnTap()` utility (`Core/Utilities/Keyboard.swift`),
same as the workout session and equipment screens.

### Weekly waist/neck/hip

`LogBodyMeasurementsView` — waist (goes to HealthKit), neck (local-only,
`BodyMeasurementLogStore`), and hip (local-only, shown only when
Biological Sex is Female in Settings). Reached from Home via
`WeeklyMeasurementsReminderBanner` and from `AppRoute.logBodyMeasurements`.
No toggle-gating here — unlike the old combined `LogWeightView`, this
screen exists specifically for these fields, so they're always shown.

`WeeklyMeasurementsReminderBanner` (`Features/Dashboard/Components/`) —
nudges toward this screen once a week. Visible from the most recent
Saturday (inclusive) until *both* waist and neck have been logged since
then; resets the following Saturday. The neck half of the check is a
synchronous local read (`BodyMeasurementLogStore.logs`, always fresh on
every render); the waist half needs an async HealthKit query, cached in
`@State` and refreshed on `.onAppear` and on `scenePhase` becoming
`.active` (so leaving the app open across a day boundary without ever
navigating away still re-checks). Missing neck alone is enough to show
the banner immediately, without waiting on the HealthKit round-trip —
an earlier version gated the *entire* banner behind that async load
finishing, which meant a slow or stalled HealthKit call could suppress
a reminder the local data alone already knew was needed.

### Correcting a past entry

`MeasurementLogHistoryView` (reached from `LogBodyMeasurementsView`'s
"History" toolbar button, and per-week via a pencil icon on each
`WeeklyReportView` card) lists past waist/neck/hip entries merged by
calendar day, with tap-to-correct (`EditMeasurementEntryView`) and
swipe-to-delete. Added because there was previously no way to fix a
typo in a past entry short of a one-off migration script.
`BodyMeasurementLogStore` gained `update(_:)`/`remove(id:)` for this;
`BodyMetricsHealthKitServicing` gained
`deleteWaistSample(date:)` (matched by exact sample start date, not
just calendar day, since more than one sample can land on the same
day).

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

## Body Profile and the Navy body-fat estimate

Added after the original phases shipped, in response to wanting the
Weekly Report to show body fat % even on weeks without a direct
scale/manual reading. `UserSettings` gained two optional fields —
`biologicalSex: BiologicalSex?` and `heightCm: Double?` — entered once
in a "Body Profile" section on `SettingsView`, used for nothing except
picking which variant of the U.S. Navy circumference formula applies
(`NavyBodyFatCalculator`, in `Domain/Health/`). Both are `nil` until
the user fills them in; the app never requires them.

`BodyMeasurementLog` gained a second optional field, `hipCm`, needed
only for the women's Navy formula (the men's formula doesn't use hip
at all). Both `neckCm` and `hipCm` are now `Optional`, and
`LogWeightView` saves a `BodyMeasurementLog` when *either* toggle is
on — logging just a neck or just a hip measurement is valid, not only
both together. The "Hip" toggle only appears on `LogWeightView` when
`biologicalSex == .female`.

`NavyBodyFatCalculator.estimate(sex:heightCm:waistCm:neckCm:hipCm:)`
is a pure function (±3–4% accuracy vs. hydrostatic weighing, per the
published U.S. Navy method) that returns `nil` outside its formula's
valid domain (e.g. waist not exceeding neck) rather than a nonsensical
result. `NavyBodyFatCalculator.fillGaps(...)` merges actual HealthKit
body-fat-% readings with estimates computed from that day's
waist/neck(/hip) — an actual reading for a day is never overridden by
an estimate; this is strictly a gap-filler, used by
`WeeklyBodyReportStore` (see `Docs/Features/WeeklyReport.md`).

## Future extensions

- Inches/cm toggle for waist, neck, hip, and height, matching the
  existing lb/kg toggle for weight.

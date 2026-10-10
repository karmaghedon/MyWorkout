# Weekly Report

## Purpose

Groups weight/body-fat-%/waist/neck history into weekly summary cards
— min/max/average weight, latest body fat %, waist, and neck readings,
and week-over-week deltas — so trends are visible without opening
Apple's Health app. Nothing here is stored: every card is recomputed
from HealthKit plus local neck/hip logs each time the screen appears.

## Windowing algorithm

`WeeklyBodyReportEngine.reportCards(bodyMass:waist:neck:bodyFatPercent:)`
is a pure function (no HealthKit or persistence dependency) that
groups samples by **actual weigh-in cadence**, not fixed calendar
weeks:

```
windowStart = first weight sample's date
while windowStart <= last weight sample's date:
    nominalEnd = windowStart + 7 days
    nextBoundary = first weight-sample date >= nominalEnd
                   (or lastSampleDate + 1 day if none — closes the final window)
    window = [windowStart, nextBoundary)   // half-open
    record window; windowStart = nextBoundary
```

A window is "~7 days but stretches to the next actual log": logging
every day for a week produces one 7-day window per boundary sample;
logging sparsely (e.g. every 2–3 days) folds those readings into one
longer window rather than manufacturing empty weeks; a gap of several
weeks between weigh-ins produces one window per gap rather than
silently interpolating. The final window always closes at
`lastSampleDate + 1 day` if no later sample exists to define its end.

Per window: weight `min`/`max`/`avg` over every weight sample in range.
Body fat %, waist, and neck all use the **latest** reading in range,
not an average — all three are logged far less often than weight, so
averaging would wash out a real reading with stale zeros. Each
metric's delta compares against the same metric in the *previous*
window and is `nil` when either window is missing that metric
(including always for the first window, which has no predecessor).

## Main types

- `DatedValue` — a generic `(date, value)` pair; the common shape both
  HealthKit samples and local `BodyMeasurementLog` entries get mapped
  to before reaching the engine.
- `WeeklyBodyReportCard` — one window's aggregated summary
  (`windowStart, windowEnd, weightMin/Max/Avg, weightAvgDelta,
  waistLatest, waistDelta, neckLatest, neckDelta,
  bodyFatPercentLatest, bodyFatPercentDelta`). `id` is `windowStart`,
  since windows never repeat a start date. The engine has no way to
  tell whether `bodyFatPercentLatest` for a given window is an actual
  HealthKit reading or a `NavyBodyFatCalculator` estimate — that
  merge happens one layer up, in `WeeklyBodyReportStore`.
- `WeeklyBodyReportEngine` — the pure windowing/aggregation function
  above.
- `WeeklyBodyReportCardView` — the per-week card UI, extracted from
  `WeeklyReportView` so `MonthlyBodyReportView` (see Month drill-down
  below) can render it too without duplicating formatting logic.
- `MonthlyBodyReportView` — one month's cards, pushed from a month row
  on `WeeklyReportView`.
- `WeeklyBodyReportStore` — `@MainActor ObservableObject`, `.task`-
  loaded rather than persisted.
  `reload(bodyMeasurementLogs:sex:heightCm:)` fetches weight/waist/
  body-fat-% from HealthKit, merges the actual body-fat-% readings with
  `NavyBodyFatCalculator.fillGaps(...)` estimates computed from that
  day's waist/neck(/hip), and takes local neck/hip logs plus
  `UserSettings.biologicalSex`/`heightCm` as parameters (rather than
  depending on `BodyMeasurementLogStore`/`UserSettingsStore` directly)
  — `@StateObject` properties in `MyWorkoutApp` can't reference sibling
  `@StateObject`s during initialization, so `WeeklyReportView`, which
  already holds all of them as `@EnvironmentObject`s, bridges them at
  call time.

## HealthKit integration

`BodyMetricsHealthKitServicing` (introduced in Phase 1 for writes)
gained three read methods: `weightSamples(since:)`,
`waistSamples(since:)`, and `bodyFatPercentSamples(since:)`, all
returning `[DatedValue]` sorted oldest first via `HKSampleQuery`.
`bodyFatPercentSamples` converts HealthKit's 0–1 fraction back to the
0–100 scale every other body-fat-% value in this app uses. There is no
live `HKObserverQuery` push — a change made directly in Apple's Health
app won't appear until `WeeklyReportView` is next opened. Documented
future extension, not needed for v1.

## UI

Each window's card (`WeeklyBodyReportCardView`) shows weight's average
(with a min–max range when they differ) respecting
`UserSettings.bodyWeightUnitSystem`, plus body-fat-%/waist/neck rows
that are omitted entirely (not shown as zero or blank) when a window
has no reading for that metric. Deltas render as a `▲`/`▼`/`–` glyph
with magnitude, with no color-coded "good/bad" judgment — this app
doesn't assume whether a user's goal is to gain or lose. An empty
state prompts logging a weigh-in when there's no data yet, and a plain
error message surfaces a HealthKit read failure. Reached from Progress
(`ProgressHubView`) via a "Body" section's "Weekly Report" row and the
`AppRoute.weeklyReport` route.

### Month drill-down

`WeeklyReportView` used to stack every weekly card newest-first in one
continuously growing scroll — fine for a few months of weigh-ins, but
one very long list with no structure above the week level once history
stretched past that. It's now the top-level screen in a two-level
drill-down, the same pattern `HistoryView` uses for workout logs:

- `WeeklyReportView` groups `weeklyBodyReportStore.cards` by the month
  of each card's `windowStart` and lists one row per month (name, week
  count), newest month first.
- Tapping a month pushes `MonthlyBodyReportView`, which renders that
  month's cards with `WeeklyBodyReportCardView` — the exact same card
  view the top-level screen used to render directly, extracted out so
  both screens share the same formatting logic (week-range text,
  per-unit weight/delta formatting) without duplicating it.

A month is naturally bounded (four or five weeks at most), so unlike
the old flat list this drill-down page needs no pagination of its own.

## Testing

`WeeklyBodyReportEngineTests` is the real coverage this phase's plan
called for: exact 7-day boundaries (each boundary sample starts its
own window, per the half-open definition), sparse/irregular cadence
(nearby samples fold into one window; a large gap starts a new one),
a single sample, empty input, and waist/neck latest-vs-average and
delta-nil-on-missing-data behavior. Pure function, no mocks needed.
`NavyBodyFatCalculatorTests` covers `fillGaps` separately (see
`Docs/Features/WeightTracking.md`). `MockBodyMetricsHealthKitService`
gained `weightSamples`/`waistSamples`/`bodyFatPercentSamples` stubs
for any future test exercising `WeeklyBodyReportStore` itself — same
hard rule as every other domain in this app: no test may construct a
real `HKHealthStore`-backed service.

## Future extensions

- Live updates via `HKObserverQuery` instead of `.task`-on-appear.
- A visual (Swift Charts) view of the same windows, complementing
  Phase 6's continuous line chart.

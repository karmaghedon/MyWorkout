# Body Progress

## Purpose

A combined, multi-metric progress chart — weight, body fat %, waist,
neck, calories, and steps, all toggle-selectable and plotted together
on one chart — complementing `WeeklyReportView`'s aggregated weekly
cards (this screen plots every individual sample instead of a
per-window summary). Reworked significantly from its original v1
(weight + optional waist/neck) after seeing a reference design: this
doc describes the current shape, not the history of how it got here
(see git history for that).

## Main types

- `DateRangeOption` (`Features/Shared/Components/DateRangePicker.swift`)
  — `1W`/`1M`/`3M`/`6M`/`1Y`/`All`, the first reusable date-range
  component in this app. `.all` returns `nil` from `startDate(from:)`,
  meaning "no lower bound." Each non-`.all` case also supports
  `steppedBackward(from:)`/`steppedForward(from:)`, stepping an anchor
  date by exactly one window length — this is what lets the screen
  page through history rather than always showing "the last N months
  from today."
- `DateRangePicker` — a thin segmented `Picker` wrapper over
  `DateRangeOption`.
- `TrendSmoother.movingAverage(_:windowDays:)`
  (`Domain/BodyReport/TrendSmoother.swift`) — a pure trailing-average
  function producing the smoothed weight trend line, tested in
  isolation (`TrendSmootherTests`).
- `ActivityHealthKitServicing`/`ActivityHealthKitService`
  (`Domain/Health/Services/`) — read-only step-count access, separate
  from `BodyMetricsHealthKitServicing` since steps are activity data,
  not a body metric, and this app never writes them. Uses
  `HKStatisticsCollectionQuery` (day-bucketed sums, since step data
  arrives as many small samples throughout the day) rather than the
  `HKSampleQuery` the other HealthKit reads in this app use.
- `BodyProgressView` — owns its own `@State` sample arrays and both
  HealthKit service instances (mirroring `LogWeightView`/
  `LogNutritionView`'s testable-injection pattern) rather than a
  dedicated store; date-range filtering happens entirely client-side
  over history fetched once, so switching ranges or paging re-renders
  instantly with no new HealthKit query.

## One chart, six independently-normalized metrics

Weight, body fat %, waist, neck, calories, and steps are all
toggle-selectable chips; whichever are active plot together on one
`Chart`. Each active metric's values are min-max normalized to a
common 0–100 display range independently (`normalize(_:referenceMin:
referenceMax:)`) before plotting, rather than sharing one literal
numeric axis — weight (lb/kg), body fat % (0–100), circumferences
(cm), calories (kcal), and steps (count) are different units on
wildly different scales, so a shared literal axis would flatten most
series into invisible near-zero lines. The chart's y-axis is hidden
entirely (`.chartYAxis(.hidden)`) since normalized values have no
independent meaning on their own — real numbers are surfaced two other
ways:

- **Summary tiles** above the chart, one per active metric: a
  first-vs-last delta (▲/▼, no color-coded "good/bad" judgment — same
  reasoning as `WeeklyReportView`) for point-in-time metrics (weight,
  fat %, waist, neck), or a period average for running daily totals
  (calories, steps) — `ProgressMetric.isDailyAggregate` governs which.
- **Tap-to-inspect**: tapping anywhere on the chart (`.chartOverlay`
  translating the tap location to a date via `proxy.value(atX:)`)
  shows a small card with that date's real value per active metric,
  matched to the nearest sample within a 3-day tolerance (so a sparse
  metric like waist doesn't show a misleadingly "current" reading from
  weeks earlier).

Weight is the only metric with a Swift Charts native legend-driving
color assignment removed in favor of manual `.foregroundStyle(Color)`
per mark — `.chartForegroundStyleScale` requires a `KeyValuePairs`
literal, which can't be built dynamically from the toggle-selected set
at runtime. The colored metric chips double as the legend instead: a
selected chip's fill color is exactly the color its line renders in.

Weight uniquely renders as two series: raw daily dots, and a smoothed
`TrendSmoother` trend line (both normalized together using the raw
dots' min/max, so the trend line sits correctly among them) — matching
the "individual readings are noisy, the trend line is what matters"
reference this screen was rebuilt to match.

## Paged date range

`windowEnd` (default `.now`) is the anchor; the visible window is
`[selectedRange.startDate(from: windowEnd), windowEnd]`. The ◀/▶
buttons call `steppedBackward`/`steppedForward` to move the anchor by
exactly one window length, clamped so stepping forward never exceeds
`.now` (nothing to show in the future) and disabled entirely for
`.all` (no fixed length to step by). Changing the range picker itself
resets `windowEnd` back to `.now`.

## Units

Weight respects `UserSettings.bodyWeightUnitSystem` (introduced in
Phase 5 — independent from the training-weight `unitSystem`). Body fat
% is 0–100. Waist and neck stay in centimeters. Calories are kcal.
Steps are a raw count. None of these have a unit toggle beyond
weight's lb/kg.

## Future extensions

- A dedicated store if this screen ever needs to share fetched samples
  with another screen (not needed today).
- Manual override entry for steps, if HealthKit-only ever proves
  insufficient (deliberately deferred — see `Docs/Features/WeeklyReport.md`
  and the project roadmap for the "HealthKit only" decision).

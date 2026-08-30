# Body Progress

## Purpose

A continuous line chart of weight over time, with optional waist/neck
panels, complementing `WeeklyReportView`'s aggregated weekly cards
(this screen plots every individual sample instead of a per-window
summary).

## Main types

- `DateRangeOption` (`Features/Shared/Components/DateRangePicker.swift`)
  — `1M`/`3M`/`6M`/`1Y`/`All`, the first reusable date-range component
  in this app. `.all` returns `nil` from `startDate(from:)`, meaning
  "no lower bound" rather than some arbitrarily distant date.
- `DateRangePicker` — a thin segmented `Picker` wrapper over
  `DateRangeOption`.
- `BodyProgressView` — owns its own `@State` sample arrays and a
  `BodyMetricsHealthKitServicing` instance (mirroring `LogWeightView`/
  `LogNutritionView`'s testable-injection pattern) rather than a
  dedicated store; range filtering happens entirely client-side over
  the full fetched history, so switching ranges re-renders instantly
  without a new HealthKit query.

## One chart, multiple lines

Weight, waist, and neck all plot on a single `Chart`, color-coded by
metric via `.foregroundStyle(by: .value("Metric", ...))`, which also
gives Swift Charts a free legend. Weight (lb/kg) and waist/neck (cm)
are different units sharing one numeric axis — a real tradeoff, since
Swift Charts has no simple secondary-axis support — but a combined
chart is the explicitly requested design over separate panels per
metric (an earlier iteration split waist/neck into their own chart
specifically to avoid this unit mismatch; that was superseded by this
one-graph, multiple-lines request). Weight is always shown; waist and
neck are toggled on independently and simply omitted from the `Chart`
body when off or empty for the selected range.

## Units

Weight respects `UserSettings.bodyWeightUnitSystem` (the same
body-specific unit setting `LogWeightView`/`WeeklyReportView` use,
introduced in Phase 5 — independent from the training-weight
`unitSystem`). Waist and neck stay in centimeters, matching every
other body-metrics screen in this app.

## Future extensions

- A dedicated `BodyProgressStore` if this screen ever needs to share
  fetched samples with another screen (not needed today — nothing else
  reads raw, unaggregated samples).
- Trend annotations (e.g. a rolling average line) if raw samples prove
  too noisy to read at a glance.

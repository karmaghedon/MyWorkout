# Dashboard (Home)

## Purpose

`DashboardView` is the Home tab's screen — a quick-glance summary of
today plus the fastest paths into starting a workout or logging body
metrics/nutrition. It was never documented despite several rounds of
changes; this describes its current shape.

## Main types

- `DashboardView`
- `WeeklyMeasurementsReminderBanner`
- `WeeklySummaryCard` (`Docs/Features/WeightTracking.md` covers its
  tappable day-dot behavior)
- `TodayNutritionCard` (`Docs/Features/Nutrition.md`)
- `DashboardStoreErrorsView`

## Move secondary analytics off Home

Home used to stack about a dozen sections — a greeting, a "Next Up"
card, a "Today" stats card, nutrition, a "Log Weight" quick action, a
"New Personal Records" card, a "Recovery" warning card, an "Overview"
stats card (total workouts/latest/alert count), and a "Recent Activity"
list — on one long scroll. Several of those (Personal Records, the
Recovery card, the Overview stats, Recent Activity) were already fully
duplicated by sections in the Analytics tab
(`PersonalRecordsSection`, `RecoveryWarningsSection`,
`PerformanceWarningsSection`, `AnalyticsOverviewSection`,
`RecentWorkoutsSection` — see `Docs/Features/Analytics.md`), so Home
was showing the same information twice rather than giving it a second,
different treatment. Home now only keeps what's either a primary
action or genuinely a "today" glance, and drops everything else in
favor of a single link into Analytics:

- `needsAttentionBanner` — one row, shown only when
  `analyticsCache.recoveryWarnings.count + analyticsCache.
  performanceWarnings.count > 0`, linking to `AppRoute.analytics`. This
  replaced both the old "Recovery" card (which rendered a warning's
  full title/message/severity) and the old "Overview" card's alert
  count — Home only needs to say *that* something needs attention and
  let Analytics' own Alerts tab show the detail.
- The old "Next Up" section merged directly into the hero card (see
  below) instead of being a second, competing call to action below it.
- The old "Today" stats card (workouts/sets logged today) was dropped
  entirely — `WeeklySummaryCard`'s "This Week" numbers already cover
  the same ground with more context, so the two cards were redundant.

## Hero card merges "Next Up"

`heroCard` branches on `activeWorkoutStore.hasActiveWorkout`:

- **Active workout**: "Resume Workout" (unchanged).
- **No active workout**: if `suggestedNextTemplate` (the least
  recently performed template, never-performed treated as most
  overdue) exists, the hero itself shows that template's name and
  "Last done <relative date>" / "Not started yet", with "Start
  Workout" starting that specific template directly
  (`startSuggestedWorkout(_:)`) and a smaller "Choose a different
  workout" link falling back to `onStartWorkout` (switches to the
  Workout tab to pick manually). With no templates yet, it falls back
  to the original generic "Ready to train?" prompt.

This used to be two separate cards (a generic "Ready to train?" hero,
plus a "Next Up" section below it suggesting the same template) — one
primary action reads more clearly than two stacked ones for the same
decision.

## Current card order

Top to bottom, as of the most recent reorder (explicitly requested —
not derived from any particular UX principle, just what reads best in
practice):

1. Header (greeting + today's date)
2. `DashboardStoreErrorsView` — any store's persistence error
3. `needsAttentionBanner` — conditional, see above
4. `WeeklyMeasurementsReminderBanner` — the waist/neck weekly reminder,
   visible from Saturday until both are logged that week
   (`Docs/Features/WeightTracking.md`)
5. `WeeklySummaryCard` — "This Week" workout/set counts plus the 7-day
   tappable calendar strip
6. `bodyMetricsQuickActionsSection` — "Log Weight" quick action
7. `heroCard` — Start/Resume Workout, with "Next Up" merged in (see
   above)
8. `todaysNutritionSection` — `TodayNutritionCard`

There's no "Log Nutrition" quick action alongside "Log Weight" — see
`Docs/Features/Nutrition.md`, `TodayNutritionCard` already links to
`AppRoute.logNutrition` itself, so a second entry point would be pure
duplication.

## Regression focus

- hero branches correctly on active-workout state, and on whether a
  template exists to suggest
- `needsAttentionBanner` only appears when there's at least one
  recovery or performance warning, and its count matches
  `analyticsCache`'s combined total
- card order matches the list above after any future reorder request

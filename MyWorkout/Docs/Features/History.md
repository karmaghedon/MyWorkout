# History

## Purpose

`HistoryView` is the "past workouts" screen reached from Progress
(`ProgressHubView`) via its "History" row and the `AppRoute.history`
route — the single screen for browsing finished `WorkoutLog`s (see
`Docs/Features/WorkoutSessions.md` for how a log is produced).

## Main types

- `HistoryView` — top-level month list
- `MonthHistoryView` — one month's day-grouped workouts
- `WorkoutLogDetailView` — one workout's full detail (summary, every
  completed exercise's sets, per-exercise notes)

## Month drill-down

`HistoryView` used to list every day that ever had a workout, grouped
by day, in one continuously growing list with a manual "Load More"
button (20 day-groups at a time). For anyone with more than a few
months of history, that became one very long scroll with no real
structure above the day level, and "Load More" is an awkward substitute
for real pagination.

It's now a two-level drill-down instead:

- `HistoryView` groups `logStore.logs` by the calendar month of each
  log's date and lists one row per month — month name, workout count,
  total sets that month — newest month first, computed fresh in
  `regroup()` whenever `logStore.logs` changes.
- Tapping a month pushes `MonthHistoryView`, which re-derives that
  month's logs into day-grouped `Section`s (the exact rendering
  `HistoryView` used to do directly) via `WorkoutCard` rows linking to
  `WorkoutLogDetailView`.

A month is naturally bounded (at most daily workouts for ~30 days), so
`MonthHistoryView` needs no pagination of its own — the old "Load
More" button is gone entirely, not replaced with a different mechanism.

`WeeklyReportView` (`Docs/Features/WeeklyReport.md`) was given the same
month-drill-down treatment for the same reason, once the pattern proved
out here.

## Regression focus

- month rows sort newest-first, with correct workout/set counts per
  month
- `MonthHistoryView` reproduces the old day-grouped, newest-first
  rendering exactly for whatever month it's given
- empty history still shows the "No Workouts Yet" empty state at the
  top level

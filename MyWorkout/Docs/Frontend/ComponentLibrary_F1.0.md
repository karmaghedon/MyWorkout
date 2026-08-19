Version: 2.0
Last Updated: 2026-08-19
Status: Active

# MyWorkout Component Library

All components live in `Features/Shared/Components/`. Every one reads its
colors, type, spacing, and radius from `AppTheme` (see
`DesignSystem_F1.0.md`) rather than hardcoded values. Built during Phase
F2, driven by the Design Rule: *no screen redesign begins until every
reusable component it depends on exists.*

Several were built directly to eliminate duplication found by auditing
existing screens — those note the sites they replaced. A few were built
ahead of any consumer, matching the spec even where no current screen
needs them yet; those are marked accordingly and are fair game for the
F3+ screen redesigns to adopt.

---

## Buttons

### PrimaryButton
The solid, accent-filled call to action. Supports a loading state (spinner
replaces the label, control disables) and an optional leading icon.
**Used by:** `CustomExerciseFormView`, `CreateWorkoutTemplateView`.

### SecondaryButton
Bordered, lower-emphasis counterpart to `PrimaryButton` — the less
important action in a pair (e.g. "Cancel" beside "Save"). Tinted
`Color.primary`, not `accent` — see Design System's "Accent contrast"
note on why bordered/tinted-text buttons don't use the brand color
directly. **Not yet consumed** — built ahead of a screen that needs a
paired primary/secondary action.

### DestructiveButton
Bordered, `AppTheme.error`-tinted button for a destructive action; the
confirmation dialog itself is the caller's responsibility.
**Used by:** `BarbellInventorySection` ("Reset Inventory to Default" —
replaced a plain red-tinted `Button`).

### IconButton
A single icon as a tappable control with a guaranteed 44×44pt minimum
touch target, even when the icon itself is drawn smaller. Replaces the
`Image(systemName:).buttonStyle(.plain)` pattern, which had no
touch-target guarantee.
**Used by:** `RestTimerBadge` (stop), `StoreErrorBanner` (dismiss).

### FloatingActionButton
Circular, elevated icon button — the only component that reaches for
`AppTheme.Elevation`, since it must visually float above whatever it's
layered on. **Not yet consumed** — no screen has a FAB-shaped action yet.

---

## Cards

### AppCard
The base card surface: standard padding, background, and corner radius
around arbitrary content. `WorkoutCard`, `MetricCard`, and
`InformationCard` build on it directly.
**Used by:** `WorkoutTimerCardView`, `InventorySectionCard`,
`DashboardStatsView`, `CurrentSetCardView` (all retrofitted off a
hand-rolled `.background(RoundedRectangle...)` pattern that had been
duplicated four times).

### InformationCard
Title + short supporting line, e.g. a dashboard tile.
**Not currently consumed** — used by `DashboardView`'s `dashboardLink`
(itself built to replace the old `DashboardCard`, which lived
incorrectly in `Domain/Analytics/Models` — a View in the Domain layer)
until the F3 Home redesign replaced that tile-menu layout with
`QuickActionRow` rows (see "Status & metrics" below). Left in the
library — it's a reasonable fit for future tile-style content.

### MetricCard
A single glanceable number in its own card (a strength estimate, a
personal record).
**Used by:** `StrengthTrendView`'s current-1RM card.

### WorkoutCard
An icon-badge row for a workout-related item (template, session, log
entry) — icon in an accent-tinted circle, title, caller-supplied
subtitle content.
**Used by:** `RecentWorkoutsSection`, `HistoryView`, `TemplatesView`,
`StartWorkoutView`. These four screens had near-identical hand-rolled
versions of this exact row before extraction.

---

## Status & metrics

### Chip
A compact capsule label — a previous-performance value, a set counter.
**Used by:** `PreviousPerformanceView`, `ExerciseSessionHeaderView`
("Set N" indicator).

### ProgressBadge
A capsule that carries a status color, for severity/state indicators.
**Used by:** `RecoveryWarningsSection` — this fixed a real bug: every
warning severity (low/medium/high) previously rendered the same orange
regardless of level; now high severity renders in `AppTheme.error`.

### MetricView
A compact label-over-value stack without its own card surface, for use
inside a parent card that already provides the background.
**Used by:** `DashboardStatsView`'s Workouts/Latest/Alerts row.

### InfoBadge *(pre-existing, unchanged)*
Tag-style descriptor on `.thinMaterial`. **Used by:** `ExerciseHeaderView`,
`ExerciseMusclesView`.

### InfoRow
Label-and-value row (renamed from `DetailRow`, moved from
`Features/ExerciseLibrary/` into `Features/Shared/Components/` since it's
generic, not exercise-specific).
**Used by:** `ExerciseOverviewView`.

### QuickActionRow
Compact icon-badge row with a trailing chevron, for a menu-style
navigation destination rather than workout content — visually close to
`WorkoutCard` (same icon-badge treatment) but terminated with a chevron
since it always represents "tap to go elsewhere," and not scoped to
workout-specific items the way `WorkoutCard`'s naming and doc comment are.
**Used by:** `DashboardView`'s Progress/Manage sections (Analytics,
Strength, Templates, Equipment, Custom Exercises, Backup & Data) — built
during the F3 Home redesign to replace six near-identical `InformationCard`
tiles with a scannable list.

---

## Section headers

### SectionHeader
A section-level title (`AppTheme.Typography.sectionTitle`), centralized
so the treatment can evolve in one place.
**Used by:** `DashboardView`'s `dashboardSection` and recent-activity
section, `InventorySectionCard`, `DashboardStatsView`'s "Overview"
heading.

### CardHeader
A card's title row with room for a trailing accessory (a chip, a button),
baseline-aligned. **Not yet consumed** — `ExerciseSessionHeaderView` has a
similar-looking title+chip row but intentionally wasn't migrated to it:
that header uses the larger `screenTitle` weight (it's the most prominent
element on the active-workout screen), while `CardHeader` is fixed to
`cardTitle`. Forcing the migration would have visually demoted it.

### ScreenHeader
A screen-level title for a scrolling root screen not carried by
`.navigationTitle`.
**Used by:** `DashboardView`'s header — since the F3 redesign, this
renders a time-of-day greeting ("Good morning") rather than the static
"MyWorkout" wordmark, per `AppTheme.Typography.heroTitle`'s own doc
comment ("the Dashboard's top-of-screen greeting").

---

## Empty / loading / error states

### AppEmptyStateView *(pre-existing, unchanged)*
Icon + title + message for an empty screen. Three more screens
(`StrengthTrendView`, `TemplatesView`, `StartWorkoutView`) had hand-rolled
duplicates of this exact pattern before being migrated onto it.

### LoadingState
Centered spinner with an optional caption — the counterpart to
`AppEmptyStateView`/`ErrorState` for a screen still fetching content.
**Not yet consumed** — the app is fully local/synchronous today, so
nothing currently shows a loading state, but it's here for when one is
needed.

### ErrorState
Full-screen failure state (icon/title/message, tinted `AppTheme.error`).
Distinct from `StoreErrorBanner` (below), which is a small, dismissible
inline banner rather than a full-screen state.
**Not yet consumed.**

### StoreErrorBanner *(pre-existing)*
Dismissible inline banner for a `StoreError`. Migrated its icon/border
color from hardcoded `.orange` to `AppTheme.error` and its dismiss button
to `IconButton`.
**Used by:** `DashboardView`'s error reporting surface.

---

## Other pre-existing components (unchanged)

- **ValidatedNameField** — form field with centralized name validation.
- **FlowLayout** — wrapping layout for tag/chip collections.

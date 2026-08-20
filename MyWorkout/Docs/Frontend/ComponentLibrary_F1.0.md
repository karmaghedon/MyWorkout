Version: 2.2
Last Updated: 2026-08-20
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

A later cross-screen audit found that "every one reads from `AppTheme`"
wasn't fully true yet — several components (`InfoBadge`, `AppEmptyStateView`,
`ErrorState`, `LoadingState`, `MetricCard`, `ProgressBadge`,
`InformationCard`, and `WorkoutCard`) still had a raw `.headline`/
`.caption`/`.subheadline` font left over from before extraction. That pass
also found and fixed a handful of components with no guaranteed 44×44pt
touch target and a couple of decorative icons not hidden from VoiceOver.
Entries below reflect the corrected state; components marked
"*(pre-existing, unchanged)*" below genuinely still are.

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
**Used by:** `RestTimerBadge` (stop), `StoreErrorBanner` (dismiss),
`LoggedSetsView` (delete set — replaced a hand-rolled 28×28pt button
found during the touch-target audit), `CustomExerciseRow` (restore —
replaced a `.buttonStyle(.borderless)` icon button with the same gap).

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
**Used by:** `StrengthTrendView`'s current-1RM card. Its label previously
used raw `.caption` instead of `AppTheme.Typography.caption`; fixed
during the cross-screen font-token audit.

### WorkoutCard
An icon-badge row for a workout-related item (template, session, log
entry) — icon in an accent-tinted circle, title, caller-supplied
subtitle content, and a trailing `Spacer()` so the row always fills its
available width rather than hugging its content.
**Used by:** `RecentWorkoutsSection`, `HistoryView`, `TemplatesView`,
`StartWorkoutView`, `DashboardView`'s Recent Activity section. The first
four screens had near-identical hand-rolled versions of this exact row
before extraction. The trailing `Spacer()` was added when the F3 Home
redesign put `WorkoutCard` inside a plain `VStack` for the first time
(every prior consumer sits inside a `List`, whose rows auto-stretch to
full width) — without it, each row centered instead of staying
left-aligned, since a `List` row's automatic full-width behavior had
been silently doing the job this component should do itself.

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
regardless of level; now high severity renders in `AppTheme.error`. Its
`.caption.bold()` font is now built from `AppTheme.Typography.caption`
rather than the raw system font.

### MetricView
A compact label-over-value stack without its own card surface, for use
inside a parent card that already provides the background. Its value text
has `.minimumScaleFactor(0.7)` so a long value (e.g. a template name in
the "Latest" slot) shrinks to fit instead of hard-truncating with an
ellipsis — added during the touch-target/text-overflow audit.
**Used by:** `DashboardStatsView`'s Workouts/Latest/Alerts row.

### InfoBadge
Tag-style descriptor on `.thinMaterial`.
**Used by:** `ExerciseHeaderView`, `ExerciseMusclesView`. Its icon is now
`.accessibilityHidden(true)` and the row is a single combined
accessibility element — previously a VoiceOver user would hear the
icon's raw SF Symbol name as a separate, confusing stop before the label
text. Also switched its `.font(.caption)` to `AppTheme.Typography.caption`.

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

### AppEmptyStateView
Icon + title + message for an empty screen. Three more screens
(`StrengthTrendView`, `TemplatesView`, `StartWorkoutView`) had hand-rolled
duplicates of this exact pattern before being migrated onto it. Title and
message previously used raw `.headline`/`.subheadline`; now
`AppTheme.Typography.cardTitle`/`label`.

### LoadingState
Centered spinner with an optional caption — the counterpart to
`AppEmptyStateView`/`ErrorState` for a screen still fetching content.
**Not yet consumed** — the app is fully local/synchronous today, so
nothing currently shows a loading state, but it's here for when one is
needed. Its caption previously used raw `.subheadline`; now
`AppTheme.Typography.label`.

### ErrorState
Full-screen failure state (icon/title/message, tinted `AppTheme.error`).
Distinct from `StoreErrorBanner` (below), which is a small, dismissible
inline banner rather than a full-screen state.
**Not yet consumed.** Title and message previously used raw
`.headline`/`.subheadline`; now `AppTheme.Typography.cardTitle`/`label`.

### StoreErrorBanner *(pre-existing)*
Dismissible inline banner for a `StoreError`. Migrated its icon/border
color from hardcoded `.orange` to `AppTheme.error` and its dismiss button
to `IconButton`.
**Used by:** `DashboardView`'s error reporting surface.

---

## Other pre-existing components (unchanged)

- **ValidatedNameField** — form field with centralized name validation.
- **FlowLayout** — wrapping layout for tag/chip collections.

## Workout Session components (FDL-020)

Live in `Features/WorkoutSession/Components/` and
`Features/WorkoutSession/`, not `Features/Shared/Components/` — scoped to
the Workout session screen specifically rather than general-purpose.
Still built on `AppTheme` tokens throughout.

### CompactWorkoutTimerBar
Single-row, opaque-background timer bar pinned above the scrolling
exercise list via `LazyVStack`/`Section`/`pinnedViews: [.sectionHeaders]`.
Replaces the full-width `WorkoutTimerCardView` on the session screen for
both layouts; `WorkoutTimerCardView` itself is left in place, unused,
rather than deleted.

### SetChecklistRow
One checklist row — checkbox, title/subtitle, optional plate `Chip` —
shared by both warm-up and working-set rows in the Checklist layout.
Guarantees a 44×44 touch target around its visually smaller (26×26)
checkbox circle, matching `IconButton`'s convention.

### ChecklistExerciseSessionCardView
Checklist-layout sibling of `ExerciseSessionCardView` — renders warm-up
and working sets as `SetChecklistRow`s instead of a single stepper.
Selected per exercise card by the `WorkoutSessionLayout` setting
(`WorkoutExerciseListView` branches between this and
`ExerciseSessionCardView`).

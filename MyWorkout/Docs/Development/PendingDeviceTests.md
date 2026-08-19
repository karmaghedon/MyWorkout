# Pending Device Tests

A working checklist for the batch of Blueprint F3-F7 feature work
implemented while the physical device was unreachable. Everything below
compiled successfully (`xcodebuild build`) but has **not** been run on
device yet. Go through this list top to bottom once the phone is
reconnected; delete this file once everything's checked off and folded
into the normal commit/doc flow.

Each entry: what changed, where, and exactly what to check.

---

## F3 — Home

### PR Highlights
- **What:** New "New Personal Records" card on Home, shown only when a
  set logged *today* matches (or beats into) an all-time personal
  record for that exercise.
- **Test:** Log a set today that ties or exceeds your current best for
  some exercise (check current bests on the Progress tab first). Return
  to Home — the card should appear with that exercise, weight, and
  reps. If nothing today matches a PR, the card should be entirely
  absent (not an empty card).

### Next Workout
- **What:** New "Next Up" card on Home suggesting the
  least-recently-performed template (a never-done template counts as
  most overdue), with a play-button that starts it directly.
- **Test:** With no active workout, confirm the card shows a sensible
  template (check against your actual template history — it should be
  whichever one you haven't done in the longest time, or one you've
  never done). Tap the play button — it should start that workout and
  land you on the active session screen, same as tapping it from Start
  Workout. Then start any workout from elsewhere and return to Home —
  the "Next Up" card should disappear while a workout is active (the
  hero card owns that state instead).

## F4 — Workout

### Finish Summary + Workout Insights
- **What:** After tapping "Finish Workout" → "Save Workout" on the
  existing confirmation dialog, a new full-screen "Workout Complete"
  summary now appears instead of returning straight to Start Workout:
  duration/exercises/sets, a "+X%/-X% volume vs last time" line (only
  shown if you've done this exact template-named workout before), and
  a "New Personal Records" card for any exercise where this session's
  best set beat (or tied) your prior all-time best for that exercise.
  Tapping "Done" dismisses the summary and returns to Start Workout,
  same as before.
- **Test:** Finish a workout where you log a set heavier (or same
  weight/more reps) than your previous best for that exercise —
  confirm it shows up under "New Personal Records" with the right
  weight/reps. Finish a workout for a template you've done before with
  a different total volume — confirm the volume comparison line shows
  and the percentage looks right. Finish a workout for a *brand new*
  template (first time ever) — confirm the volume line is absent (no
  "previous" to compare against) but the summary still shows
  correctly otherwise. Confirm "Done" returns you to Start Workout, not
  back into the (now-finished) session.

## F5 — Library

### Rich Exercise Cards / Muscle Chips
- **What:** Every exercise row (Library list, template exercise pickers,
  template editor) now shows an equipment icon badge and
  muscle/equipment/difficulty as small chips instead of a plain
  "Muscle • Equipment • Type" text line.
- **Test:** Open the Library tab and confirm rows look right at normal
  and larger Dynamic Type sizes (chips wrapping/truncating gracefully,
  not overlapping). Check the same row style still looks right inside
  Create Workout Template's exercise picker and the Template Editor's
  "Add Exercises" picker — those reuse the same component.

### Filters
- **What:** New filter icon in the Library toolbar — Equipment,
  Difficulty, and "Favorites Only," with a "Clear Filters" option when
  any are active. An empty state appears if a combination matches
  nothing.
- **Test:** Try each filter individually and combined. Confirm the
  filter icon fills in (`line.3.horizontal.decrease.circle.fill`) when
  any filter is active, and reverts to the outline icon when cleared.
  Filter down to nothing (e.g. Favorites Only with no favorites yet) and
  confirm the empty state shows instead of a blank list.

### Favorites
- **What:** Star button on each Library row (not inside the row's own
  tap target — it's a sibling next to the `NavigationLink`, specifically
  to avoid nesting one button inside another's label).
- **Test — this is the one I'd flag as highest-risk to verify, since I
  couldn't test the interaction live:** tap the star on a few rows and
  confirm it toggles without also navigating into that exercise's detail
  view (i.e. tapping the star should NOT trigger the row's NavigationLink).
  Conversely, tapping anywhere else on the row should navigate to detail
  without toggling the star. Confirm favorited state survives leaving and
  returning to the tab (persisted).

### Related Exercises
- **What:** Exercise detail screens now show up to 4 other exercises
  sharing the same muscle group, at the bottom, each pushing to its own
  detail view.
- **Test:** Open an exercise with several others in the same muscle
  group — confirm the "Related Exercises" section appears and lists
  sensible exercises (not itself). Tap into one — confirm it pushes
  correctly and *that* screen also shows its own related exercises
  (recursive navigation). Open an exercise that's the only one in its
  muscle group (if any) — confirm the section is simply absent, not an
  empty section header.

## F6 — Progress

### Volume Trend
- **What:** New "Volume Trend" section on the Analytics screen — a bar
  chart of total training volume per week, over the last 12 weeks that
  have any data.
- **Test:** With fewer than 2 weeks of history, confirm it shows the
  "Log a few more weeks..." message instead of a broken/empty chart.
  With more history, confirm the bars look proportionally right (a
  heavier/higher-rep week should show a taller bar) and the weight unit
  matches your Settings (lb/kg).

### Consistency
- **What:** New "Consistency" section on Analytics — current streak
  (consecutive weeks with a workout) and a 12-week activity strip.
- **Test:** Confirm the streak number matches reality (count backward
  from this week — the first week with no workout should stop the
  streak). Confirm the strip has exactly 12 segments and the filled
  ones line up with weeks you actually trained.

## F7 — Profile

### About
- **What:** New "About" section on the Profile tab hub, pushing to a
  new `AboutView` with the app name, version/build number, and a short
  description.
- **Test:** Confirm the version/build number shown matches the actual
  installed build (check Xcode's build settings or the Info.plist if
  unsure) rather than showing "—" (the fallback if `Bundle.main` lookup
  fails).

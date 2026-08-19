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

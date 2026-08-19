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

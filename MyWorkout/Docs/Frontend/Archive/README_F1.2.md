# MyWorkout F1.2 — Native App Shell

## Add

- `MyWorkout/App/Navigation/AppTab.swift`
- `MyWorkout/App/Navigation/AppShellView.swift`

## Replace

- Replace the existing `DashboardView.swift` with the supplied file.
- Replace the existing `MyWorkoutApp.swift` with the supplied file.

## Xcode

Ensure both new Swift files are added to the **MyWorkout app target**.

## Test

- App launches on Home.
- All five tabs appear.
- Each tab can navigate independently.
- Switching tabs preserves each tab's pushed screen.
- Starting/resuming a workout still works.
- An active workout cannot be replaced.
- Store errors still appear on Home.
- Project builds successfully.

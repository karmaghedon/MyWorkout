# MyWorkout F1.3 — Shared Navigation Components

## Add

- `MyWorkout/App/Navigation/AppTabLabel.swift`

## Replace

- `MyWorkout/App/Navigation/AppTab.swift`
- `MyWorkout/App/Navigation/AppShellView.swift`

## Architecture

- `AppTab` is the single source of truth for tab identity and metadata.
- `AppTabLabel` is the reusable native tab presentation.
- `AppShellView` owns selection, navigation paths, and route resolution.
- No business logic is placed in the tab label.
- No custom tab bar styling is introduced in F1.3.

## Build checks

- App launches on Home.
- All five tab titles and symbols display.
- VoiceOver announces the intended destination names.
- Each tab preserves its navigation state.
- Existing workout behavior remains unchanged.

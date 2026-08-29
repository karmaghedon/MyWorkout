# MyWorkout F1.4 — Custom Tab Presentation

## Add

- `MyWorkout/App/Navigation/MyWorkoutTabBar.swift`

## Replace

- `MyWorkout/App/Navigation/AppTab.swift`
- `MyWorkout/App/Navigation/AppShellView.swift`

## Keep unchanged

- `AppTabLabel.swift`
- All destination root views
- All navigation paths and route resolution
- All workout business logic

## Scope

This phase changes only the visual tab presentation.

The native `TabView` remains responsible for:
- selected destination
- independent tab content
- state preservation
- native lifecycle behavior

The custom `MyWorkoutTabBar`:
- renders all five destinations
- emphasizes Workout in the center
- supports light and dark appearance through semantic colors/material
- exposes selected state to VoiceOver
- maintains minimum practical tap areas
- does not read or mutate workout state

## Validation

- App launches on Home.
- All five destinations are selectable.
- Center Workout button is visually emphasized.
- Selected state is visible for every destination.
- Tab switching preserves navigation state.
- Light and dark appearance are readable.
- Larger text sizes do not clip destination labels.
- VoiceOver announces tab labels and selected state.
- Workout start, logging, completion, and history remain unchanged.

# Workout Templates

## Purpose

Templates define reusable exercise sequences for starting workouts.

## Main types

- `WorkoutTemplate`
- `WorkoutTemplateStore`
- `WorkoutTemplateRepository`
- `FileWorkoutTemplateRepository`

## Main views

- `TemplatesView`
- `CreateWorkoutTemplateView`
- `TemplateEditorView`
- `StartWorkoutView`

## Capabilities

- create
- edit
- delete
- duplicate
- add exercises
- remove exercises
- filter exercise selection by equipment
- validate template names
- restore default templates on first launch

## Exercise refresh

Loaded or imported templates are refreshed through an exercise registry so built-in exercise definitions can evolve without duplicating lookup behavior throughout the UI.

## Persistence

Templates are stored in a versioned JSON envelope in Application Support.

Legacy UserDefaults and legacy unwrapped file formats are migrated where supported.

Unreadable persisted templates are not automatically overwritten.

## Duplicate naming

Template duplication produces:

```text
Original Copy
Original Copy 2
Original Copy 3
```

## Regression focus

- first-launch defaults
- load and migration
- add/update/delete
- duplicate naming
- replace-all
- exercise refresh
- persistence failure protection

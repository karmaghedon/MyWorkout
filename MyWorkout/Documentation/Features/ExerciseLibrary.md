# Exercise Library

## Purpose

The exercise library is both a selection source for workouts and the foundation of the exercise encyclopedia.

## Exercise information

An exercise may include:

- identity and name
- equipment
- exercise type
- difficulty
- primary muscles
- secondary muscles
- instructions
- coaching tips
- common mistakes
- safety warnings
- progression rule
- progression strategy

## Sources

Exercises may come from:

- built-in seed data
- user-created custom exercises
- template references
- historical workout references

## Registry

`ExerciseRegistry` centralizes lookup across these sources.

Features should not create independent name-only lookup implementations.

## Main views

- `ExerciseLibraryView`
- `ExerciseRowView`
- `ExerciseDetailView`
- `ExerciseHeaderView`

Reusable detail components include:

- `ExerciseOverviewView`
- `ExerciseMusclesView`
- `ExerciseInstructionsView`
- `ExerciseTipsView`
- `ExerciseWarningsView`

## Identity compatibility

Current records prefer stable exercise identifiers.

Historical logs that predate identifiers may fall back to exercise-name matching.

This fallback must remain limited to backward compatibility.

## Future extensions

Potential additions:

- search
- favorites
- images
- videos
- muscle diagrams
- alternatives
- variations
- per-exercise history
- education depth by experience level

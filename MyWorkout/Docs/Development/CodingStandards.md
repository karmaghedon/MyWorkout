# Coding Standards

## Architecture first

Before writing code, determine:

- ownership
- dependency direction
- reuse potential
- persistence impact
- test strategy

## SwiftUI views

Views should:

- compose components
- bind to state
- send actions
- present navigation and feedback

Views should not:

- read or write files
- perform complex analytics
- implement progression rules
- duplicate validation
- contain large persistence workflows

## Reusable components

Extract repeated UI or a coherent reusable section.

Do not extract trivial one-off fragments solely to reduce line count.

## File size

At approximately 150–200 lines, review whether a view or type has multiple responsibilities.

This is a review trigger, not an absolute limit.

## State ownership

- local visual state: `@State`
- shared application state: environment-injected store
- derived deterministic values: logic engine or computed property
- persisted collection: store plus repository
- cross-screen active session: `ActiveWorkoutStore`

## Main actor

Observable stores that publish UI state should be `@MainActor`.

Background work must not read mutable published collections directly.

## Protocols

Introduce a protocol when:

- a consumer needs a narrow capability
- test substitution adds value
- multiple implementations are plausible
- dependency direction improves

Do not create protocols for every concrete type automatically.

## Models

Models should represent product concepts.

Prefer typed models and enums over string literals.

Persisted models must consider backward-compatible decoding.

## Validation

Validation belongs in centralized validators.

Do not duplicate name or numeric validation in individual views.

## Errors

User-data errors must be surfaced through observable state.

Console logging may supplement, but never replace, user-visible error handling.

## Persistence

- prefer atomic writes
- use schema envelopes for evolving formats
- preserve unreadable data
- inject persistence dependencies for tests
- migrate only after a successful new-format write

## Units

Stored workout weights use a canonical representation.

Conversion is centralized in `WeightConversion`.

Avoid direct conversion formulas in views.

## Accessibility

Review:

- Dynamic Type
- VoiceOver labels
- sufficient contrast
- semantic grouping
- minimum tap targets
- meaningful button labels
- keyboard dismissal for forms

## Formatting

- use descriptive names
- keep functions focused
- use `MARK` sections for larger files
- avoid commented-out code
- avoid unexplained magic numbers
- prefer early guards
- keep public interfaces smaller than implementations

## Tests

New deterministic logic requires tests.

Fixed regressions should receive tests whenever practical.

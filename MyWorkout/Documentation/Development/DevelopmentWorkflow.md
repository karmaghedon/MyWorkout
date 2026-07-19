# Development Workflow

## Core sequence

Every architectural step follows:

```text
Architecture review
   ↓
Small scope definition
   ↓
Implementation
   ↓
Build
   ↓
Tests
   ↓
Behavior check
   ↓
Commit
   ↓
Documentation update
```

## One concept per step

A step should introduce one meaningful concept.

Good:

```text
Add backup replacement protocols
Build
Test
Commit
```

Avoid:

```text
Reorganize folders
Rewrite persistence
Redesign UI
Add analytics
```

in a single change.

## Before implementation

Answer:

### Architecture

- Which layer owns this responsibility?
- Does an existing abstraction already solve it?
- Is a reusable component appropriate?
- Is the dependency direction correct?
- Is a protocol necessary, or would it be premature?

### Product

- Which product goal does this support?
- Does the data model represent the product rather than one screen?
- Will the design scale to years of history?

### Persistence risk

- Could this overwrite unreadable data?
- Does it change a Codable model?
- Does it require migration?
- Does it affect backup compatibility?
- Is rollback possible?

### Testing

- Is the logic deterministic?
- Can a regression test reproduce the behavior?
- Does a dependency need injection?
- Can the test avoid touching production files or UserDefaults?

## Existing-file rule

When changing an existing source file, provide the complete replacement file.

This reduces copy/paste errors and makes review safer.

## New-file rule

New types should include:

- a focused responsibility
- correct target membership
- a clear folder location
- no unnecessary abstraction

## Build discipline

Every commit must compile.

Preferred commit sizes:

- one protocol introduction
- one component extraction
- one store test suite
- one persistence migration
- one folder-movement batch

## Commit prefixes

```text
feat:
fix:
refactor:
test:
docs:
chore:
```

## Review after each step

Confirm:

- project builds
- tests pass
- behavior is preserved unless intentionally changed
- persistence compatibility is protected
- no duplicate component or abstraction was introduced
- documentation still matches the code

## Current resume point

```text
Phase 18 complete after documentation files are installed.
Next: Phase 19.1 — repository and folder structure audit.
```

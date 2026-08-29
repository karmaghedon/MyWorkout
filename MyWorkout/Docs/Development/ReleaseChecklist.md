# Release Checklist

## 1. Source control

- [ ] Working tree is clean
- [ ] Release branch is current
- [ ] All intended commits are pushed
- [ ] No temporary files or duplicate test files remain
- [ ] No secrets or personal paths are committed

## 2. Build

- [ ] Debug build succeeds
- [ ] Release build succeeds
- [ ] iPhone simulator build succeeds
- [ ] Physical-device build succeeds
- [ ] No new warnings
- [ ] Deployment target is correct
- [ ] Signing and capabilities are correct

## 3. Automated tests

- [ ] Full `MyWorkoutTests` suite passes
- [ ] Logic engine tests pass
- [ ] Validator tests pass
- [ ] Store persistence tests pass
- [ ] Migration tests pass
- [ ] Backup tests pass
- [ ] No flaky async tests

## 4. Fresh install

- [ ] App launches
- [ ] Default templates appear
- [ ] Default equipment appears
- [ ] Default settings appear
- [ ] Exercise library loads
- [ ] No persistence error banners appear
- [ ] A first workout can be completed

## 5. Upgrade path

- [ ] Existing workout history loads
- [ ] Existing templates load
- [ ] Existing custom exercises load
- [ ] Existing settings load
- [ ] Existing equipment loads
- [ ] Legacy data migrates where supported
- [ ] Migration does not remove old data before successful save

## 6. Workout session regression

- [ ] Start a workout
- [ ] Log warm-up and working sets
- [ ] Start a rest timer
- [ ] Navigate away
- [ ] Resume active workout
- [ ] Timer remains correct
- [ ] Logged sets remain correct
- [ ] Starting another workout does not overwrite the active one
- [ ] Finish creates history
- [ ] Cancel clears active persistence

## 7. Templates and custom exercises

- [ ] Create template
- [ ] Edit template
- [ ] Add exercise
- [ ] Remove exercise
- [ ] Duplicate template
- [ ] Create custom exercise
- [ ] Duplicate-name validation works
- [ ] Archived-name validation works
- [ ] Custom exercise appears in template selection
- [ ] Referential deletion restrictions work

## 8. Equipment and units

- [ ] Edit barbell
- [ ] Add/delete plates
- [ ] Add/delete dumbbells
- [ ] Reset inventory
- [ ] Switch pounds/kilograms
- [ ] Weight display is correct
- [ ] Plate calculator respects inventory
- [ ] Warm-up loads remain accurate

## 9. Analytics and recovery

- [ ] Analytics loads with no history
- [ ] Analytics loads with history
- [ ] Personal records display
- [ ] Volume by muscle group displays
- [ ] Recovery warnings display when expected
- [ ] No future log affects current recovery analysis
- [ ] Strength trend displays correctly

## 10. Backup and export

- [ ] Export current backup
- [ ] Inspect JSON file
- [ ] Import current backup
- [ ] Import supported older backup
- [ ] Reject unsupported future version
- [ ] Reject malformed JSON without replacing stores
- [ ] Reject invalid custom exercises before replacement
- [ ] CSV export succeeds

## 11. Persistence failure behavior

- [ ] Corrupted history is not overwritten
- [ ] Corrupted templates are not overwritten
- [ ] Corrupted settings are preserved
- [ ] Active-workout save failure is surfaced
- [ ] Store error banner can be dismissed
- [ ] Successful later save clears the relevant error

## 12. UI and accessibility

- [ ] Light mode
- [ ] Dark mode
- [ ] Large Dynamic Type
- [ ] VoiceOver review of primary flows
- [ ] Keyboard dismissal
- [ ] Tap targets
- [ ] Empty states
- [ ] Error banners
- [ ] Destructive confirmations

## 13. Performance

- [ ] Dashboard launch is responsive
- [ ] Analytics calculation is acceptable with large history
- [ ] Template and exercise lists scroll smoothly
- [ ] Active workout updates do not trigger excessive persistence
- [ ] No obvious retain cycles
- [ ] No repeated expensive calculation in SwiftUI `body`

## 14. Documentation

- [ ] README matches current features
- [ ] Architecture paths match Phase 19 structure
- [ ] Persistence versions are documented
- [ ] Backup version is documented
- [ ] Roadmap resume point is current
- [ ] Release notes prepared

## 15. Release metadata

- [ ] Marketing version updated
- [ ] Build number updated
- [ ] App icon verified
- [ ] Display name verified
- [ ] Privacy declarations reviewed
- [ ] Release notes finalized
- [ ] Archive created
- [ ] Archive validated

## Final sign-off

- [ ] Version 1.0 architecture review completed
- [ ] No known data-loss defect
- [ ] No critical or high-severity regression
- [ ] Backup recovery path verified
- [ ] Release approved

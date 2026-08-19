Version: 1.2
Last Updated: 2026-08-19
Status: Active

MyWorkout Frontend Roadmap
Phase F1 — Navigation Foundation ✅ COMPLETE
F1.1 — Navigation Architecture
Inspect existing navigation.
Inventory all screens.
Define five primary destinations.
Document navigation rules.
Define push/sheet/full-screen presentation.
Define active workout navigation.
Build not affected (documentation only).
Success Criteria
Architecture documented.
Navigation rules documented.
Screen ownership finalized.
F1.2 — Native App Shell
Introduce AppShellView.
Introduce AppTab.
One NavigationStack per tab.
Preserve environment objects.
Home launches first.
Preserve navigation state.
Prevent active workout loss.
Build
Must compile.
F1.3 — Shared Navigation Components
Centralize tab metadata.
Remove duplicated navigation code.
Accessibility labels.
Reusable tab configuration.
Build
Must compile.
F1.4 — Custom MyWorkout Tab Bar
Replace only visual presentation.
Keep native TabView.
Emphasize Workout destination.
Support:
Light Mode
Dark Mode
Dynamic Type
VoiceOver
Build
Must compile.
F1.5 — Stateful Workout Destination
Workout
Resume
Rest Timer
Route directly to active workout.
Prevent workout replacement.
Preserve session.
Build
Must compile.
Phase F2 — Design System ✅ COMPLETE
Goal
Create every reusable UI component before redesigning screens.
Result
17 components built in Features/Shared/Components/, all reading from
AppTheme tokens. Full inventory and per-token rationale in
DesignSystem_F1.0.md and ComponentLibrary_F1.0.md. Several sub-phases
also eliminated real duplication found by auditing existing screens
(four hand-rolled icon-row variants unified into WorkoutCard, three
hand-rolled empty states unified into AppEmptyStateView, a misplaced
View in the Domain layer deleted). A WCAG contrast audit of the accent
color found and fixed a pre-existing failure — see FDL-010.
F2.1 — Color System
Create semantic colors.
Accent
Background
Grouped Background
Card Background
Success
Warning
Error
Secondary
Tertiary
Requirements
Light Mode
Dark Mode
High Contrast
Build
Must compile.
F2.2 — Typography
Create reusable typography.
Examples
Hero Title
Screen Title
Section Header
Card Title
Metric
Caption
Footnote
Monospaced Timer
Requirements
Dynamic Type
Accessibility
Build
Must compile.
F2.3 — Spacing System
Create reusable spacing constants.
Examples
AppSpacing.xs
AppSpacing.sm
AppSpacing.md
AppSpacing.lg
AppSpacing.xl
Standardize
Card padding
List spacing
Screen margins
Section spacing
Build
Must compile.
F2.4 — Corner Radius & Elevation
Standardize
Corner radius
Shadows
Stroke widths
Card elevation
No hardcoded values.
F2.5 — Button Library
Create reusable buttons.
PrimaryButton
SecondaryButton
DestructiveButton
IconButton
FloatingActionButton
Requirements
Loading
Disabled
Press animation
F2.6 — Card Library
Create
AppCard
WorkoutCard
MetricCard
InformationCard
No duplicated card styling.
F2.7 — Status Components
Create reusable
Badge
Chip
MetricView
ProgressBadge
InfoRow
F2.8 — Empty & Error States
Create reusable
EmptyState
LoadingState
ErrorState
Every screen should use these.
F2.9 — Section Components
Create reusable
SectionHeader
CardHeader
ScreenHeader
F2.10 — Motion System
Create
Standard animation durations
Haptic wrappers
Press animation
Card transitions
No magic animation values.
Phase F3 — Home Experience
Redesign Dashboard.
Goals
Welcome
Resume Workout
Today's Progress
Recovery
Weekly Summary
PR Highlights
Next Workout
Architecture first.
Phase F4 — Workout Experience
Improve workout flow.
Includes
Template Cards
Workout Dashboard
Session Progress
Finish Summary
Exercise Flow
Workout Insights
Phase F5 — Exercise Library
Transform into an exercise encyclopedia.
Includes
Rich Exercise Cards
Filters
Muscle Chips
Equipment
Difficulty
Favorites
Related Exercises
Custom Exercises
Phase F6 — Progress
Analytics experience.
Includes
Strength Trends
Volume Trends
Muscle Distribution
Personal Records
Consistency
Recovery
Future Body Metrics
Phase F7 — Profile
Consolidate
Settings
Equipment
Units
Backup
Restore
About
Phase F8 — Premium Polish
Includes
Haptics
Micro Animations
Accessibility Audit
Performance Audit
Skeleton Loading
Transition Polish
Final UI Review
UI Component Library
UI
│
├── Components
│
├── Cards
│   ├── AppCard
│   ├── WorkoutCard
│   ├── MetricCard
│   └── InformationCard
│
├── Buttons
│   ├── PrimaryButton
│   ├── SecondaryButton
│   ├── DestructiveButton
│   ├── IconButton
│   └── FloatingActionButton
│
├── Badges
│   ├── Badge
│   ├── Chip
│   ├── ProgressBadge
│   └── MetricBadge
│
├── Sections
│   ├── ScreenHeader
│   ├── SectionHeader
│   └── CardHeader
│
├── Metrics
│   ├── MetricView
│   ├── InfoRow
│   ├── ProgressRing
│   └── StatView
│
├── EmptyStates
│   ├── EmptyState
│   ├── LoadingState
│   └── ErrorState
│
└── Layout
    ├── AppSpacing
    ├── AppCorners
    ├── AppShadow
    ├── AppAnimation
    └── AppTypography
Development Rules
Every frontend feature must follow this workflow:
Architecture
        ↓
Reusable Components
        ↓
Implementation
        ↓
Build
        ↓
Testing
        ↓
Documentation Update
Build Rules
Every step must:
Introduce only one architectural concept.
Compile successfully.
Preserve existing functionality.
Avoid duplicated UI.
Prefer native SwiftUI before custom implementations.
View Rules
Views should assemble components only.
Business logic belongs in:
Stores
Services
Engines
Models
Views should remain thin.
Component Rules
If a UI pattern appears twice, extract it before continuing.
Design Rules
No screen redesign begins until every reusable component it depends on exists.

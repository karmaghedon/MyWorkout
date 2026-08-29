Version: 2.0
Last Updated: 2026-08-19
Status: Active

# MyWorkout Design System

Phase F2 built out every token and reusable component this document
describes. Source of truth for tokens is `Core/Theme/AppTheme.swift`;
source of truth for components is `Features/Shared/Components/`. This
document explains the *why* behind each — read the code for exact values.

---

## Colors

`AppTheme` exposes:

- `accent` — the ember-orange brand color. Same RGB in light and dark
  mode (a brand color, not a surface, so it doesn't need to flip). Carries
  separate high-contrast variants that activate automatically under iOS's
  Increase Contrast accessibility setting.
- `accentMuted` — `accent` at 15% opacity, for tinted backgrounds behind
  accent-adjacent content (chips, icon badges, suggestion banners).
- `success` — same dynamic/high-contrast treatment as `accent`.
- `warning` / `error` — system `.systemOrange` / `.systemRed`. Left as
  system colors deliberately: Apple already tunes these for light/dark
  and Increase Contrast, so there's nothing custom to add.
- `onAccentFill` — fixed black. Content color for anything drawn directly
  on a *solid* `accent` fill (buttons, the FAB). See "Accent contrast" below.
- `background` / `cardBackground` / `subtleFill` / `groupedBackground` —
  the four adaptive surface tiers, each a thin wrapper over the matching
  system semantic color so they flip for light/dark automatically.
- `secondaryText` / `tertiaryText` — the label hierarchy below primary
  text, wrapping `.secondaryLabel` / `.tertiaryLabel`.

### Accent contrast

The bright accent orange (`#FF5733`) fails WCAG AA contrast (3.15:1,
needs 4.5:1) as *text or icon foreground* against light or white
surfaces, and as white-on-accent inside a filled button. Rather than
soften the brand color, the fix is compositional:

- **Solid accent fill** (a button's background, the FAB): pair with
  `onAccentFill` (black), not white. Black-on-accent measures 6.66:1.
- **Accent-tinted surface** (`accentMuted`, e.g. a chip background):
  pair with `Color.primary` — SwiftUI's system label color, which is
  already black in light mode and white in dark mode, so it stays
  correct as the muted tint's actual rendered color shifts between a
  light peach (light mode) and a near-black tint (dark mode).
- **Decorative icons** (a timer glyph, a badge icon) may still use
  `accent` as their own color, since WCAG's non-text 3:1 floor is easier
  to clear and these aren't conveying information through color alone.

Never pair `accent` directly with white text, or use `accent` as a text
color on a plain background — both measured below 4.5:1 in the audit
that prompted this section.

---

## Typography

`AppTheme.Typography` is a small, named scale — reach for these instead
of raw `.font(.system(...))` calls:

| Token | Use |
|---|---|
| `heroTitle` | App-level moment (Dashboard's top greeting) |
| `screenTitle` | A screen/detail view's primary heading when not carried by `.navigationTitle` |
| `cardTitle` | Title for a card-sized unit of content |
| `sectionTitle` | Grouping title (dashboard sections, card group headers) |
| `label` | Standard control/body label |
| `caption` / `footnote` | Secondary and tertiary supporting text |
| `eyebrow` | Small all-caps-style label above a value |
| `numeric(_:weight:)` | Big glanceable numbers — timers, weight, reps. Rounded design, monospaced digits baked in so a live value doesn't jitter as it changes width |

All are built on system text styles (`.system(.title2, design: .rounded)`,
etc.) rather than fixed point sizes, so they scale with Dynamic Type.
`numeric` is the one exception — its call sites (steppers, timers) sit in
fixed-geometry controls where growing text would break layout.

---

## Spacing

`AppTheme.Spacing`: `xs` (4) / `sm` (8) / `md` (12) / `lg` (16) / `xl` (24).
A five-step scale, consistently used for padding, stack spacing, and
section gaps.

## Corner Radius

`AppTheme.Radius`: `control` (10, form controls / icon badges) and `card`
(18, card surfaces). Every hardcoded corner-radius literal found in the
codebase during F2 was consolidated onto one of these two values.

## Stroke Width

`AppTheme.StrokeWidth`: `hairline` (1, borders/dividers) and `ring` (4,
emphasized circular strokes like the rest-timer progress ring).

## Elevation

`AppTheme.Elevation.cardShadow` — one restrained shadow spec, applied via
the `.appShadow(_:)` view modifier. The design language favors flat
surfaces that separate with `cardBackground` alone; this exists for the
rare case where something must visually float (currently: the FAB).

## Motion

`AppTheme.Motion`: `standard` (0.25s, default state-change pace),
`linearContinuous` (1.0s, the rest-timer ring), `cardTransition`
(opacity + move-from-top, for a surface entering/leaving alongside other
content). Press feedback needs no token — `.borderedProminent`,
`.bordered`, and `.plain` already animate presses natively, and every
button in the library rides on one of those. Tactile feedback is
`Haptics` (`Core/Utilities/Haptics.swift`), not a motion concern.

---

## Component library

See `ComponentLibrary_F1.0.md` for the full inventory — 17 components
across buttons, cards, status indicators, empty/loading/error states,
and section headers, all in `Features/Shared/Components/`.

## Accessibility

- Every icon-only control goes through `IconButton`, which enforces a
  44×44pt minimum touch target regardless of the icon's visual size.
- Colors carry high-contrast variants where the system doesn't already
  provide them (see "Accent contrast" above).
- Typography rides system text styles for Dynamic Type support, with the
  documented exception of `numeric`.

## Dark Mode

Every token is dynamic (`UIColor` trait-based providers for custom
colors, system semantic colors for the rest) — nothing in the token set
is a flat, mode-blind value. As of the appearance-mode setting (Profile
→ Settings → Appearance), the user can also pin the app to Day or Night
regardless of the system setting, or leave it on Auto.

## Dynamic Type

Handled by building typography on system text styles rather than fixed
point sizes (see Typography above).

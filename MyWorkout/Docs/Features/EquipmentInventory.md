# Equipment Inventory

## Purpose

The equipment inventory represents the user's available loading equipment and supports realistic plate and warm-up recommendations.

## Main types

- `EquipmentInventory`
- `PlateInventory`
- `DumbbellInventory`
- `EquipmentInventoryStore`
- `PlateCalculator`

## Stored information

- unit system
- barbell weight
- plates and quantities
- dumbbells and quantities

## Default inventory

The default inventory is pound-based and includes a standard barbell and common plate pairs.

Users can replace it with their real equipment.

## Capabilities

- edit barbell weight
- add plates
- add dumbbells
- delete inventory items
- reset to defaults
- convert inventory units
- calculate the smallest valid plate increment
- persist changes

## Sorting

- plates are sorted descending by weight
- dumbbells are sorted ascending by weight

## Unit behavior

Inventory values are converted when the inventory unit changes.

Workout storage remains pound-based elsewhere in the app; inventory tracks its own current unit system for loading calculations.

### Standard-pair conversion, not formula conversion

`EquipmentInventoryConverter` converts standard Olympic weights (barbell,
plates, dumbbells) using a fixed lookup table of the conventional
lb⟷kg pairs the fitness industry actually sells and markets — 2.5⟷1.25,
5⟷2.5, 10⟷5, 25⟷10, 35⟷15, 45⟷20 — rather than the raw
`WeightConversion` formula. A 45 lb bar is precisely 20.41 kg, but every
gym and manufacturer treats a "45 lb bar" and a "20 kg bar" as the same
equipment; converting by formula instead of by convention previously
produced values like 20.41165665 kg for a 45 lb barbell, which is
mathematically correct but not what any lifter means by "the 20 kg bar."
Only weights that don't match a standard pair (custom equipment) fall
back to formula conversion, rounded to a sensible precision (nearest 0.5
kg, nearest quarter-pound). Standard pairs also round-trip exactly
(45 lb → 20 kg → 45 lb), since both directions look up the same fixed
table instead of computing through lossy rounded math each way.

## Persistence

Equipment inventory uses injectable UserDefaults and a configurable persistence key.

Tests use isolated UserDefaults suites.

## Validation

Add operations reject non-positive weight or quantity values.

## Regression focus

- initial defaults
- load
- corrupted data recovery
- add and delete
- replacement
- sorting
- conversion
- smallest increment
- persistence

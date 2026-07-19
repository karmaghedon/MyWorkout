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

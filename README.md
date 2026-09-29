# Ambulance First – Active Trip UI Fix

## Updated file
- `lib/roles/customer/screens/active_trip_screen.dart`

## Fixes
1. Removed the narrow-screen Flex overflow caused by the ETA/route Row.
2. Mobile widths (<390px) now stack ETA and route information vertically.
3. Wider layouts use bounded `Expanded` columns instead of a fixed 180px route column.
4. Added `maxLines`/ellipsis to telemetry labels.
5. Reduced the map preview from 340px to 300px for a tighter mobile composition.
6. Tightened vertical section spacing.
7. Fixed the Hospital Alert heading contrast on the pale red alert surface.

The yellow/black striped rectangle in the screenshot is Flutter's debug overflow indicator. It is not an intentional UI element and should disappear once the layout overflow is fixed.

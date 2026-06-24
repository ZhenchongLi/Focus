# Focus 1.0.2 Release Notes

## New Features
- About and Help are now reachable again from the application menu.
- The About window reads its version straight from the app bundle, so it always matches the installed build (no more hardcoded version drift).

## Bug Fixes
- Audio-engine startup failures are no longer silently swallowed, so sound problems are diagnosable instead of producing mysterious silence.
- Removed misleading internal comments that contradicted the real work/break durations.

## Changes
- Updated version to 1.0.2.
- Refactored the timer into a testable `TimerModel` and moved the sine-wave sound synthesis into a dedicated `SoundPlayer`.
- Added a unit-test suite covering the timer transitions, time formatting, menu-bar title states, and the sound player.
- Removed the unused UI-test stub target.

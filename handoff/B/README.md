# B delivery and integration handoff

The complete B source is available in this repository. **The production app is still a skeleton. Today and Week are prepared for A's dependency assembly; they are not active screens yet.**

## Source locations

| B files | Location | State |
| --- | --- | --- |
| Records, shared store, formatting (3) | `Shared/` | Production source; original B commits preserved |
| SwiftData repositories (1) | `ShiftWeek/Data/SwiftDataRepositories.swift` | Production source; implements all three current ShiftCore repository protocols |
| Widget provider and view (2) | `ShiftWeekWidget/` | Production source; read-only data query and small/medium layouts |
| Today view and ViewModel (2) | `handoff/B/Features/Today/` | Complete source, outside the App target, awaiting A integration |
| Shift form and Week views/ViewModels (4) | `handoff/B/Features/Week/` | Complete source, outside the App target, awaiting A integration |

`source-manifest.json` records the hashes and intended target paths of the six prepared files. They match the files used in the separate B verification app. Do not add this handoff folder itself to an Xcode target.

## Contract required from A

The screen initializers are `TodayView(deps:)`, `WeekView(deps:)` and `ShiftFormView(deps:shift:day:)`. They use A's `AppDependencies` type with these members:

| Member | Required implementation |
| --- | --- |
| `calendar` | `Calendar`, using the shared Monday-based calendar |
| `jobs` | `JobRepository`; B supplies `SwiftDataJobRepository(context:)` |
| `shifts` | `ShiftRepository`; B supplies `SwiftDataShiftRepository(context:)` |
| `clockShift` | `ClockShiftUseCase(shifts:calendar:)` |
| `saveShift` | `SaveShiftUseCase(jobs:shifts:)` |
| `deleteShift` | `DeleteShiftUseCase(shifts:)` |
| `weekSummary` | `GetWeekSummaryUseCase(jobs:shifts:calendar:)` |
| `preview()` | Debug-only factory returning an isolated in-memory store and demo values |

A's Pay feature can use `SwiftDataPayslipRepository(context:)`. Settings and Week must share the `visaModeOn` preference key. Views and ViewModels use ShiftCore values and operations; they do not import SwiftData.

## Integration steps

1. A provides the production App entry, `AppDependencies`, four-tab shell, demo data, Settings and Pay. The current App entry only displays the App Group availability message.
2. On a feature branch based on the latest main, compare each prepared file with any new files from A. Move the six files from `handoff/B/Features/` to `ShiftWeek/Features/` without overwriting newer changes. Remove the handoff copies after successful integration so there is one source of truth.
3. Build Debug and Release. Run the current ShiftCore tests. Use A's real dependency assembly and fixed demo data to check clock in/out/clear, errors, add/edit/delete, overnight shifts, unpaid breaks, week navigation and the Settings preference.
4. Check production-store persistence after restarting. Test app-to-Widget sharing and Home Screen refresh with the correct App Group entitlements. Confirm physical-device haptics and VoiceOver operation separately.
5. Review the integrated change and merge it through the normal team workflow. Replace this status with actual results only after those checks pass.

Do not copy the separate verification app's test dependency assembly into production. It is a test fixture, not A's final implementation.

## Verification and remaining work

See [verification](VERIFICATION.md) and [contribution facts](CONTRIBUTION.md). The evidence distinguishes compiled production files, independently verified screen source, and pending integrated/device checks. Reference guide code, sample Widget values and a successful isolated test do not establish that the final group app is complete.

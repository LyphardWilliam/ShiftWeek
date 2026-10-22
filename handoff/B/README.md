# Integration and B source record

Updated 22 October 2026 against main `5d44328`. The production App now uses A's `AppDependencies` and the real Today, Week, Pay and Settings tabs. B's six screen files are active production source. This folder contains records only; do not add it to an Xcode target.

| B responsibility | Current production location |
| --- | --- |
| Stored models, shared store and formatting (3 files) | `Shared/` |
| SwiftData repositories (1 file) | `ShiftWeek/Data/SwiftDataRepositories.swift` |
| Today View and ViewModel (2 files) | `ShiftWeek/Features/Today/` |
| Shift form and Week Views/ViewModels (4 files) | `ShiftWeek/Features/Week/` |
| Widget provider and view (2 files) | `ShiftWeekWidget/` |

[source-manifest.json](source-manifest.json) records the six original screen hashes using their current repository paths. They match the original B handoff at `f15058a` and the files A moved into production in `e722197`. No duplicate handoff screen source is needed.

## Integration boundaries

The screens use `TodayView(deps:)`, `WeekView(deps:)` and `ShiftFormView(deps:shift:day:)`. A's production assembly supplies the calendar, repository protocols and C's use cases. Views do not open a SwiftData context themselves. B's repositories adapt stored records to ShiftCore domain values.

App and Widget targets must have the same schema and App Group identifier. Personal team and bundle-prefix values belong in ignored `Config/Local.xcconfig`, as described in the root README. A successful unsigned build does not verify shared storage on a physical device.

See [verification](VERIFICATION.md) for current results and limits, and [contribution facts](CONTRIBUTION.md) for original work versus later integration. Earlier isolated screen checks remain historical evidence; they are not substituted for the final production App.

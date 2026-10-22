# ShiftWeek

ShiftWeek helps students with casual jobs plan their shifts, clock in and out, and check each payslip against their own records.

## Setup

1. Open `ShiftWeek.xcodeproj` (the app needs iOS 26.0 or later). The integrated App and Widget were built with Xcode 26.3 / Swift 6.2.4 and the iOS 26.2 SDK on 22 October 2026.
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
3. In `Config/Local.xcconfig`, set `DEVELOPMENT_TEAM` to your team ID and `BUNDLE_ID_PREFIX` to a unique prefix (for example `com.yourname`). The App Group becomes `group.<prefix>.ShiftWeek`.
4. Choose the `ShiftWeek` scheme and run.

`Config/Local.xcconfig` is ignored by git, so each person keeps their own team and prefix. Don't change the team in Signing & Capabilities.

## Tests

```bash
swift test --package-path Packages/ShiftCore
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The second command checks the simulator build without signing. Signed-device and real App Group checks are separate.

## Demo and verification

The production App includes Today, Week, Pay and Settings. In a Debug build, Settings has **Load Demo Data**. It replaces all records in that installation, so use a dedicated demo installation. Sample dates follow the current week. The optional `-demoData` launch argument also resets the samples on every launch; remove it before checking persistence across restarts.

See the [current integration and verification record](handoff/B/README.md) for source locations, attribution and the scope of completed checks.

© 2026 ShiftWeek Team

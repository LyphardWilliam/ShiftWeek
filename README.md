# ShiftWeek

ShiftWeek helps students with casual jobs plan their shifts, clock in and out, and check each payslip against their own records.

## Setup

1. Open `ShiftWeek.xcodeproj` in Xcode 27 (the app needs iOS 26.0 or later).
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
3. In `Config/Local.xcconfig`, set `DEVELOPMENT_TEAM` to your team ID and `BUNDLE_ID_PREFIX` to a unique prefix (for example `com.yourname`). The App Group becomes `group.<prefix>.ShiftWeek`.
4. Choose the `ShiftWeek` scheme and run.

`Config/Local.xcconfig` is ignored by git, so each person keeps their own team and prefix. Don't change the team in Signing & Capabilities.

## Tests

```bash
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
swift test --package-path Packages/ShiftCore
```

© 2026 ShiftWeek Team

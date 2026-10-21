# ShiftWeek

ShiftWeek helps students with casual jobs plan their shifts, clock in and out, and check each payslip against their own records.

## Integration status

The App entry is currently a skeleton. B's shared models, repositories and Widget are in the production source folders. The six Today/Week screen files are available in [B's integration handoff](handoff/B/README.md), awaiting A's production dependency assembly and App shell. The handoff includes validation scope and remaining integration checks.

## Setup

1. Open `ShiftWeek.xcodeproj` (the app needs iOS 26.0 or later). The current B delivery was built with Xcode 26.3 / Swift 6.2.4 and the iOS 26.2 Simulator SDK.
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

© 2026 ShiftWeek Team

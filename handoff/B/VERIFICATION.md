# Integrated App verification record

Updated 22 October 2026. Source baseline: main `5d44328`. Environment: Xcode 26.3, Swift 6.2.4, iOS 26.2 build SDK; iPhone 17 Pro Simulator running iOS 26.3.1. Checks below use the team's real App entry and dependency assembly.

| Check | Actual result | Scope |
| --- | --- | --- |
| App + Widget Debug build | Passed; 0 warnings, 0 errors | Production targets, unsigned generic Simulator |
| App + Widget Release build | Passed; 0 warnings, 0 errors | Production targets, unsigned generic Simulator |
| ShiftCore package | 16 tests in 4 suites passed | Current C domain rules and use cases |
| Default-signed Simulator build | Passed; 0 warnings, 0 errors | Actual App + Widget with local signing configuration |
| Physical iPhone build and installation | Passed; build has 0 warnings, 0 errors | iPhone 14 / iOS 26.3.1; personal configuration is ignored |
| Integrated App on the iPhone | Opened successfully; demo Today and Pay shown; Settings reports Widget sharing On | Real production App, sample records |
| Integrated screen acceptance | Passed Today clock/restart/error/reset, Week navigation/overnight/break, Pay comparison and Settings | Unmodified production Swift sources with an external XCTest target; test-runner warnings are separate from production build warnings |
| Integrated add/edit/delete | Passed; newly created shift appeared, edited note persisted, deletion removed it | Production UI and real repositories; isolated demo installation |
| Dark + accessibility-large screens | Flow passed; screenshots captured for Today, Week and Pay | Actual system appearance/content-size settings on iPhone 17 Pro Simulator; visual inspection recorded locally |
| Physical small + medium Home Screen Widgets | Both added; both open the App; saved-data changes appear in both | 25h06m/$733.10 before clock-in, 30h16m/$867.43 after; App Week agrees; clearing returns both to the original totals |
| Physical App restart | Clock-in remained after terminate and relaunch without demo reset | Actual Today timer resumed; launch receipt and before/after captures retained |
| Screen source manifest | All 6 current production paths and SHA-256 hashes match | Original B source preserved during A integration |

Reproduce build and package checks from the repository root:

```sh
swift test --package-path Packages/ShiftCore
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek -destination 'generic/platform=iOS Simulator' -configuration Release CODE_SIGNING_ALLOWED=NO build
```

Signed builds require each member's valid local configuration. B retains this run's full logs, source hashes, device installation receipt and screenshots in the local dated delivery folder. Build caches, databases, device identifiers and personal signing values are not published.

## Earlier independent checks

The earlier B phase checked repository CRUD/mapping, date boundaries, Decimal values, relationship deletion and disk reopening. ViewModels and screen flows were checked with C's real use cases in a separate test assembly. Widget provider queries were checked with an isolated context for populated, empty and unavailable states. These checks retain their original scope and dates.

## Acceptance still being completed

The user reported no problems when asked to check physical haptics and VoiceOver card reading/double-tap operation. This is user confirmation, not instrument measurement or a full accessibility audit. Simulator dark/large-text checks are listed above; they do not establish a complete physical-device accessibility audit. Marketing assets, the walkthrough video and final report are separate deliverables.

Saving through B's repositories calls `reloadAllTimelines()`. The provider requests a later timeline. Both are requests; iOS controls when the Widget is displayed. See [Apple's WidgetKit guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

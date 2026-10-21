# B verification record

Checked on 21 October 2026 with Xcode 26.3, Swift 6.2.4 and the iOS 26.2 Simulator SDK. Simulator interaction checks used an iPhone 17 Pro on iOS 26.3. No personal signing configuration is included.

## Current merge candidate

| Check | Result | Scope |
| --- | --- | --- |
| App + Widget Debug build | Passed; 0 warnings, 0 errors | Production source folders, unsigned simulator build |
| App + Widget Release build | Passed; 0 warnings, 0 errors | Production source folders, fresh build cache, unsigned simulator build |
| ShiftCore package | 16 tests in 4 suites passed | Current domain rules and use cases; C's tests preserved |
| Prepared screen sources | 6 hashes match the verified B delivery | `handoff/B/Features/`; not in the production App target |

Reproduce the production checks from the repository root:

```sh
swift test --package-path Packages/ShiftCore
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ShiftWeek.xcodeproj -scheme ShiftWeek \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Release CODE_SIGNING_ALLOWED=NO build
```

## Earlier independent B checks with the same source

- SwiftData repositories: in-memory CRUD, relationship mapping, sorting, date boundaries, Decimal values, missing-job errors and isolated stores.
- Disk persistence: write in one process, reopen in another, then verify job deletion cascades while unrelated records remain.
- ViewModels: real B repositories and current C use cases, including clock errors, form validation, overnight shifts, unpaid breaks, editing and week navigation.
- Separate screen verification app: three flow tests passed for Today and Week interactions; one additional large-text detail test passed. Screenshots covered light/dark layouts, large text, forms and Widget layouts.
- Widget: the actual provider query was checked against an isolated ModelContext for empty, unavailable and populated states, weekly totals, next-shift selection and read-only behaviour.

The independent screen app used a clearly labelled **test assembly**, not A's production AppDependencies. It does not prove final App integration. The Widget gallery values are samples. Earlier verification logs include tool warnings; the fresh production Debug/Release runs above both have zero warnings. Full local logs and screenshots are retained by B outside the repository; caches and test databases are not uploaded.

## Still required after A integration

- Production AppDependencies, App shell and demo data connected to all four real tabs.
- Production store survives restart through the actual App entry.
- Correctly signed App and Home Screen Widget read the same App Group store and respond to changed data.
- Physical-device haptics, VoiceOver reading and interaction, touch targets and full cross-feature acceptance.
- Final signed build, marketing assets, walkthrough video and submission documents.

Saving through B's repository calls `reloadAllTimelines()`, and the provider requests a later timeline. These are requests; iOS controls the display schedule. See [Apple's WidgetKit guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

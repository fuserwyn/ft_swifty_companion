# Swifty Companion — native iOS (SwiftUI)

Native iOS (Swift / SwiftUI) implementation of Swifty Companion. No third-party dependencies.
The Flutter implementation lives on the `master` branch.

## Requirements

- Xcode 15+ (tested on Xcode 26), iOS 16+
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to regenerate the project from `project.yml`

## Setup

1. `make env` creates `.env` from `.env.example`.
2. Fill in your 42 API credentials there (no quotes, no comments):
   ```
   INTRA_UID=...
   INTRA_SECRET=...
   ```
   `.env` is git-ignored. `Config/App.xcconfig` includes it (`#include? "../.env"`), so the values reach `Info.plist` at build time.
3. `make open` opens the project in Xcode, then press ⌘R. You can also run `make run` to build and launch in the simulator.

`SIMULATOR` sets which simulator to use: `make run SIMULATOR="iPhone 17 Pro"`.

## Structure

```
SwiftyCompanion/
  App/            entry point, theme
  Config/         AppConfig: reads credentials from Info.plist
  Models/         Student / Skill / Project + decoding of the 42 API JSON
  Services/       IntraAPIService (actor): OAuth client-credentials, token cache, retry on 401
  Views/          SearchView, ProfileView, view model, components
SwiftyCompanionTests/  unit tests (decoding, validation)
```

## Mandatory

- Two views: search and profile, with back navigation through `NavigationStack`.
- Error handling for missing `.env` credentials, empty or invalid login, unknown login (404), rate limit (429), OAuth errors and network errors.
- The profile shows login, email, mobile, level, location, wallet, evaluation points and avatar.
- Skills show level and percentage with a progress bar.
- Projects show passed and failed (plus in-progress), with a filter.
- The layout is adaptive (`LazyVGrid(.adaptive)`, `ViewThatFits`, max-width containers), with portrait/landscape, iPad and dark mode supported.

## Bonus

- The OAuth token is cached in memory and refreshed when it expires. A 401 forces one refresh and a retry.
- In Debug builds the cached token TTL is 60 s, which makes the refresh easy to show during the defense. Watch the `IntraAPI` logs in the Xcode console.

# WeighApp Current State

Last updated: 2026-06-10

## Product Summary

WeighApp is a local-only native iOS SwiftUI app for personal weight-loss habit tracking. The app is focused on consistency, not calorie tracking.

Core promise:

> Track the days that matter. Build consistency. Watch the weight trend follow.

Phase 1 scope is intentionally narrow. Do not add auth, backend sync, social features, battles, AI coaching, calories, meals, macros, food databases, barcode scanning, wearable sync, or complex health reports.

## What The App Can Do

- First-run onboarding:
  - 3-step onboarding for optional name, weight unit, baseline weights, and weekly targets.
  - Supports `kg` and `lb`.
  - Unit changes in onboarding convert starting/current/goal weight fields immediately.

- Main app shell:
  - 4 main tabs using native iOS `TabView`: Today, Progress, Goals, History.
  - Main tab headers include a top-right profile/avatar button.
  - Profile opens as a full-screen flow, not a fifth tab.

- Today:
  - Shows a compact daily check-in card.
  - If no check-in exists today, the card shows `Ready when you are` and `Start check-in`.
  - If today is already saved, the card stays visible as a full-width completed card with `Saved for today` and a small `Edit` action.
  - Shows weekly diet goal progress, current progress, streaks, and a supportive message.
  - Does not show the weight graph.

- Check-in:
  - Opens only from Today.
  - Saves or updates one check-in for today.
  - Captures diet status: `Yes`, `Mostly`, or `No`.
  - Captures movement: `Yes` or `No`.
  - Supports optional weight entry.
  - If a weight is saved, it creates or updates today’s `WeightEntry`.

- Progress:
  - Shows current weight, total lost, goal weight, 6-week weight trend chart, and monthly consistency.
  - Includes `Add past weight` for manually entering older weigh-ins from notes or prior tracking.
  - Past weight entries update the chart, history dots, and weigh-in goals without creating fake habit check-ins.

- Goals:
  - Uses a hybrid goals model.
  - Four core goals are always present and derived from the profile:
    - Follow diet X days per week.
    - Move X days per week.
    - Log weight X times per week.
    - Reach target weight.
  - `Adjust targets` edits profile targets and refreshes Today, Progress, and Goals.
  - Users can create extra goals for the same Phase 1 goal types only.
  - Extra goals can be edited or deleted through an explicit overflow menu.
  - Goal cards are informational; non-functional chevrons were removed.

- History:
  - Shows a monthly calendar.
  - Green days are on-plan, yellow days are mostly, gray days are missed.
  - Blue dots indicate weigh-ins from `WeightEntry`, including standalone past weigh-ins.
  - Shows monthly summary stats.

- Profile & settings:
  - Opened from the top-right avatar/leaf in the main tab headers.
  - Shows profile identity, optional profile photo, baseline weights, targets, preferences, and data/privacy.
  - Allows editing name, photo, starting/current/goal weight, weekly targets, and unit.
  - Unit changes convert saved profile weights, daily check-in weights, weight entries, and weight goals.
  - Includes reset local data with confirmation.

## Current Design Direction

- Native SwiftUI, mobile-first, iOS-only.
- Light warm background with neutral white cards.
- Green is now reserved mostly for primary actions, selected states, positive progress, and success moments.
- Most icons and section surfaces use neutral/slate tones to avoid the app feeling entirely green.
- Orange is used for streaks.
- Blue is used for weigh-ins and informational accents.
- Yellow and gray remain calendar status colors for `Mostly` and `Missed`.
- Bottom sheets use compact centered titles with a top-right close button and the primary CTA anchored at the bottom of the sheet.

## Technical Architecture

- Project: native Xcode SwiftUI app in `weighapp.xcodeproj`.
- Minimum app architecture:
  - `WeighApp.swift` owns the SwiftData model container.
  - `ContentView.swift` decides between onboarding and the main app based on whether a `UserProfile` exists.
  - `MainAppShell` owns tab state, profile presentation, check-in state, goal sheets, and past weight sheet.
  - `TrackerMetrics` derives visible stats from saved local data.
  - `Theme.swift` contains app colors, typography, tab metadata, and icon tone roles.
  - `Components.swift` contains shared UI pieces such as headers, cards, icon bubbles, stat cards, goal cards, progress bars, and calendar.
  - `Screens.swift` contains onboarding, main screens, profile, sheets, forms, chart, and supporting view structs.

## SwiftData Models

- `UserProfile`
  - Stores starting/current/goal weight, unit, weekly targets, optional display name, optional profile image data, and timestamps.

- `DailyCheckIn`
  - Stores one daily habit check-in: date, diet status, moved boolean, optional weight, and timestamps.
  - Weight remains for compatibility, but `WeightEntry` is the source of truth for trend and weigh-in metrics.

- `WeightEntry`
  - Stores standalone weigh-ins by date.
  - Used for current/latest weight, trend chart, history weigh-in dots, and weigh-in goals.
  - One entry per calendar day by behavior.

- `Goal`
  - Supports Phase 1 goal types only:
    - `diet_days`
    - `weight_target`
    - `movement_days`
    - `weigh_ins`
  - Has title, target/current values, period, status, and `core` marker.

## Data And Metrics Rules

- App data is local-only through SwiftData.
- No network or account system exists.
- Today’s check-in updates existing check-in for the day instead of creating duplicates.
- Saving a check-in weight upserts today’s `WeightEntry`.
- Adding a past weight upserts a `WeightEntry` for that date only.
- Habit streaks and consistency are based on real `DailyCheckIn` records, not standalone weight entries.
- Weight trend and weigh-in counts are based on `WeightEntry`.
- Core goals are recreated/normalized on app launch if missing or duplicated.
- Runtime backfill creates `WeightEntry` records from older `DailyCheckIn.weight` values when needed.

## Build And Install Notes

- Simulator build:

```sh
xcodebuild -project weighapp.xcodeproj -scheme weighapp -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

- Physical device Release build for Josue’s iPhone has been using:

```sh
xcodebuild -project weighapp.xcodeproj -scheme weighapp -configuration Release -destination 'platform=iOS,id=00008140-00096D9A3684801C' -derivedDataPath /tmp/weighapp-device-derived DEVELOPMENT_TEAM=72M2BS6DPV CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates build
```

- Device install path after Release build:

```sh
xcrun devicectl device install app --device F7489F84-2D31-534D-ACD9-77684602644F /tmp/weighapp-device-derived/Build/Products/Release-iphoneos/weighapp.app
```

- Device launch:

```sh
xcrun devicectl device process launch --device F7489F84-2D31-534D-ACD9-77684602644F com.jaguilar.weighapp
```

Known device identifiers used recently:

- CoreDevice id: `F7489F84-2D31-534D-ACD9-77684602644F`
- Xcode destination id: `00008140-00096D9A3684801C`
- Bundle id: `com.jaguilar.weighapp`

## Useful Guardrails For Future Agents

- Preserve Phase 1 scope unless explicitly changed by the user.
- Do not add calorie, meal, macro, social, auth, backend, AI, or wearable features.
- Keep copy supportive and non-shaming.
- Keep Today simple. The full check-in form should only appear after `Start check-in` or `Edit`.
- The graph belongs on Progress, not Today.
- Use explicit actions instead of decorative chevrons.
- Keep green intentional. Neutral/slate should carry most default UI hierarchy.
- Prefer updating shared components and semantic theme tokens before one-off styling.

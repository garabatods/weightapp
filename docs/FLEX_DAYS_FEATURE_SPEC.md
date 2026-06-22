# WeighApp Feature Spec — Flex Days

Last updated: 2026-06-21

## Purpose

Add **Flex Days** to WeighApp as a planned, supportive way for users to define off-plan diet days without treating them as failures.

This feature replaces the earlier idea of “streak shields.”

The product idea is:

> Plan flexibility before it happens, so life does not feel like failure.

Flex Days should keep WeighApp aligned with its core promise:

> Track the days that matter. Build consistency. Watch the weight trend follow.

## Current App Context

WeighApp is a local-only native iOS SwiftUI app for personal weight-loss habit tracking.

Current Phase 1 guardrails still apply:
- Do not add auth.
- Do not add backend sync.
- Do not add social features.
- Do not add battles or 1v1 challenges.
- Do not add AI coaching.
- Do not add calories, meals, macros, food databases, or barcode scanning.
- Do not add wearable sync.
- Do not add complex health reports.

Flex Days should fit into the existing local-only SwiftData architecture and should not expand the app into nutrition tracking.

## User-Facing Name

Use **Flex Days** in the UI.

Avoid using “cheat day” in product copy because it can feel negative or shame-based.

Acceptable internal/code terms:
- `flexDay`
- `flex`
- `plannedFlexDay`

Avoid user-facing terms like:
- Cheat
- Bad day
- Failure
- Punishment
- Offender
- Broken streak

## Feature Summary

A user can define one or more planned Flex Days.

Example:

> Saturday and Sunday are Flex Days.

On a Flex Day:
- The day does not count as a missed diet day.
- The day does not count as an on-plan diet day unless the user chooses “Stayed on plan.”
- The day can pause the streak instead of breaking it.
- The day appears as a distinct state in History.
- The app should explain the day in a supportive way.

## Recommended Version

Implement **Flex Days v1** as fixed weekday-based planned days.

Do not implement a weekly Flex Day budget yet.

### Flex Days v1 includes:

- Add Flex Days settings in Profile.
- User can enable or disable Flex Days.
- User can select weekdays: Sun, Mon, Tue, Wed, Thu, Fri, Sat.
- Today detects if the current day is a planned Flex Day.
- Check-in copy changes on Flex Days.
- Add a `flex` diet status to saved check-ins.
- History calendar gets a distinct Flex Day status color.
- Streaks pause on Flex Days instead of breaking.
- Diet goal progress excludes Flex Days from missed days.
- Monthly consistency excludes Flex Days from eligible days.

## Future Version — Not For This Task

Do not implement this yet:

### Flex Day Budget

A future version may allow the user to choose a number of Flex Days per week instead of fixed weekdays.

Example:

> 2 Flex Days per week. Use them whenever.

This is more flexible and game-like, but it requires more logic:
- Remaining Flex Days this week.
- “Use Flex Day today” action.
- Weekly reset.
- Handling unused Flex Days.

This is not part of the current implementation.

---

# UX Rules

## Profile / Settings

Add a section in Profile, likely near weekly targets or preferences.

### Section title

**Flex Days**

### Description copy

> Plan off-days ahead of time. Flex Days do not count as missed days.

### Controls

- Toggle: Enable Flex Days
- Weekday picker:
  - Sun
  - Mon
  - Tue
  - Wed
  - Thu
  - Fri
  - Sat

### Default

- Flex Days disabled by default.
- No days selected by default.

### Optional suggestion

If the user’s weekly diet target is less than 7, the app may show a subtle suggestion later:

> Your diet target leaves room for planned Flex Days.

Do not auto-select Flex Days.

## Today Screen

Today should stay simple.

Current guardrails still apply:
- The graph belongs on Progress, not Today.
- The full check-in form should only appear after Start/Edit.
- Today should not become busy.

### Normal Day Card

Keep the existing normal behavior:

- Title: `Today’s check-in`
- Status: `Ready when you are`
- Button: `Start check-in`

### Planned Flex Day Card

If today is a planned Flex Day and no check-in exists yet, the Today check-in card should change copy:

Title:

> Flex Day

Subtitle:

> Planned break

Primary action:

> Check in

Do not show extra helper copy in this compact Today card. Flex Days are already explained during onboarding/Profile and in weekly Flex copy.

### Saved Flex Day State

If the user saves today as a Flex Day:

Title:

> Flex Day saved

Subtitle:

> Streak paused, not broken.

Action:

> Edit

## Check-In Screen

On normal days, keep the current check-in:

- Did you follow your diet today?
  - Yes
  - Mostly
  - No
- Did you move today?
  - Yes
  - No
- Optional weight
- Save check-in

On planned Flex Days, change the first question.

### Flex Day Check-In

Title:

> Check-in

Subtitle:

> A quick moment for today.

Question:

> How did today go?

Options:

1. **Used Flex Day**
2. **Stayed on plan**

Then keep:

- Did you move today?
  - Yes
  - No
- Optional weight
- Save check-in

### Behavior

If the user selects **Used Flex Day**:
- Save `dietStatus = flex`.

If the user selects **Stayed on plan**:
- Save `dietStatus = yes`.
- Count it as an on-plan diet day.
- This should be treated as a bonus, not required.

Do not ask for calories, meals, notes, macros, or reasons.

## Progress Screen

Update consistency calculations to support Flex Days.

Use flex-adjusted consistency:

```txt
on-plan days / eligible days
```

Where:

```txt
eligible days = total days with check-ins excluding flex days
```

Or, for month-level consistency:

```txt
eligible days = checked-in days in the period excluding saved flex days
```

### Copy

Instead of:

> 72% on-plan this month

Use:

> 72% on-plan across non-flex days

If there are no Flex Days saved in the period, existing copy is fine.

## Goals Screen

The core “Follow diet X days per week” goal should count only `yes` days.

Flex Days do not count as completed diet days, but they also should not count as missed days.

Example:

> 3 / 5 diet days completed  
> 2 Flex Days planned this week

Do not add Flex Days as a new goal type.

Flex Days support the existing diet goal model.

## History Screen

Add a distinct Flex Day calendar state.

Current states:
- Green: On-plan
- Yellow: Mostly
- Gray: Missed
- Blue dot: Weigh-in logged

Add:
- Lavender or soft purple: Flex Day

Do not use green for Flex Days because they are not automatically on-plan.
Do not use gray because they are not missed.
Do not use yellow because yellow already means mostly.

### Legend

Update legend to include:

- Green: On-plan
- Yellow: Mostly
- Gray: Missed
- Lavender: Flex Day
- Blue dot: Weigh-in logged

### Detail/tooltip copy if day detail exists

> Flex Day  
> Planned off-plan day. Your streak was paused, not broken.

---

# Data Model

## UserProfile

Add migration-safe optional backing fields to `UserProfile`:

```swift
var flexDaysEnabledValue: Bool?
var flexWeekdayMaskValue: Int?
```

Expose computed defaults:

```swift
var flexDaysEnabled: Bool { flexDaysEnabledValue ?? false }
var flexWeekdayMask: Int { flexWeekdayMaskValue ?? 0 }
```

Weekday mask mapping:

```swift
Sunday = 1 << 0
Monday = 1 << 1
Tuesday = 1 << 2
Wednesday = 1 << 3
Thursday = 1 << 4
Friday = 1 << 5
Saturday = 1 << 6
```

## DailyCheckIn

Update diet status to include:

```swift
yes
mostly
no
flex
```

Important:

Saved historical Flex Days should be stored in `DailyCheckIn`.

Do not rely only on the current profile Flex Day settings to render past days, because the user may change their Flex Day schedule later.

Rule:
- `UserProfile.flexWeekdayMask` defines planned future/current Flex Days.
- `DailyCheckIn.dietStatus = flex` records that the user actually used a Flex Day on that specific date.

## WeightEntry

No change required.

Weight entries remain the source of truth for:
- Current/latest weight
- Trend chart
- Weigh-in dots
- Weigh-in goals

Saving a Flex Day check-in with weight should still upsert today’s `WeightEntry`.

## Goal

No new goal type should be added.

Keep Phase 1 goal types:
- `diet_days`
- `weight_target`
- `movement_days`
- `weigh_ins`

---

# Metrics Rules

## Diet Goal Progress

Counts as completed:
- `yes`

Does not count as completed:
- `mostly`
- `no`
- `flex`

However:
- `flex` should not be treated as missed.
- `flex` should not create negative language.

If the current app counts `mostly` differently, preserve existing behavior unless it conflicts with this feature.

## Movement Goal Progress

Unchanged.

Movement is independent from diet status.

A Flex Day can still include movement.

## Weigh-In Goal Progress

Unchanged.

A Flex Day can still include a weigh-in.

## Weight Trend

Unchanged.

Weight trend is based on `WeightEntry`.

## Streak Rules

Define streak as:

> Consecutive non-missed diet days, where Flex Days pause the streak instead of breaking it.

Recommended behavior:
- `yes` continues/increments the streak.
- `mostly` should follow the app’s current streak logic.
- `no` breaks the streak.
- `flex` pauses the streak and does not break it.
- A planned Flex weekday with no saved check-in also pauses the streak after the day has passed.
- Today without a check-in does not break the current streak before the day has passed.

Example:

| Day | Status | Streak |
| --- | --- | --- |
| Mon | Yes | 1 |
| Tue | Yes | 2 |
| Wed | Yes | 3 |
| Thu | Yes | 4 |
| Fri | Yes | 5 |
| Sat | Flex | 5 paused |
| Sun | Flex | 5 paused |
| Mon | Yes | 6 |

Saved Flex Today copy can say:

> Streak paused, not broken.

## Consistency Rules

Preferred consistency formula:

```txt
on-plan days / eligible days
```

Where:

```txt
eligible days = check-in days excluding flex days
```

Example:

A month has:
- 12 Yes
- 3 Mostly
- 2 No
- 3 Flex

Eligible days = 17  
On-plan days = 12  
Consistency = 12 / 17 = 71%

Copy:

> 71% on-plan across non-flex days.

Do not show Flex Days as fake successful diet days.

---

# Theme / Visual Design

Follow current design direction:
- Green is reserved mostly for primary actions, selected states, positive progress, and success moments.
- Neutral/slate should carry most default UI hierarchy.
- Orange is used for streaks.
- Blue is used for weigh-ins and informational accents.
- Yellow and gray remain calendar status colors for Mostly and Missed.

Add:
- Lavender / soft purple for Flex Days.

Suggested semantic token:

```swift
Theme.Colors.flexDay
```

Do not overuse purple outside Flex Day-specific UI.

---

# Components To Update

Likely files based on current architecture:

- `Theme.swift`
  - Add Flex Day semantic color.
  - Add any icon tone role if needed.

- `Components.swift`
  - Update calendar day rendering.
  - Update calendar legend.
  - Update shared status chips if present.
  - Update icon bubble tones if needed.

- `Screens.swift`
  - Update Profile/settings UI.
  - Update Today check-in card behavior.
  - Update Check-in sheet/screen.
  - Update Progress consistency copy/calculation display.
  - Update Goals diet progress explanatory copy.
  - Update History legend/calendar state.

- `TrackerMetrics`
  - Update streak logic.
  - Update consistency logic.
  - Update diet goal progress logic if needed.
  - Add helper methods:
    - `isPlannedFlexDay(date, profile)`
    - `isSavedFlexDay(checkIn)`
    - `eligibleDietDaysExcludingFlex(...)`
    - `plannedFlexDaysInCurrentWeek(...)`

- SwiftData models
  - Add fields to `UserProfile`.
  - Add `flex` to diet status enum/string mapping.
  - Add safe migration/default values if needed.

---

# Edge Cases

## Today is a planned Flex Day and the user stays on plan

Save as `yes`.
Count toward diet goal.
Show positive copy:

> Nice — you stayed on plan on a Flex Day.

## Today is a planned Flex Day and user uses Flex Day

Save as `flex`.
Do not count as missed.
Pause streak.

## User changes Flex Day settings later

Past saved `flex` check-ins remain Flex Days.

Future planned Flex Days follow the updated profile setting.

## User disables Flex Days

Existing saved historical `flex` days remain in History.
Future days are not treated as planned Flex Days.

## User has no check-in on a planned Flex Day

Do not automatically create a `flex` check-in.

The app may display it as planned on Today, but History should only show saved records unless the existing app already visualizes no-entry days differently.

## Weight on a Flex Day

If weight is entered, upsert `WeightEntry` as usual.

## Mostly on a planned Flex Day

In Flex Day check-in v1, do not show `Mostly`.

Only show:
- Used Flex Day
- Stayed on plan

This keeps the decision simple.

---

# Acceptance Criteria

## Profile

- User can enable Flex Days.
- User can select one or more weekdays.
- User can disable Flex Days.
- Settings persist locally through SwiftData.

## Today

- On planned Flex Days, Today card shows compact Flex Day copy: `Flex Day`, `Planned break`, `Check in`.
- On non-Flex Days, Today behaves as before.
- If Flex Day is saved, Today shows saved Flex Day state and Edit action.
- Today remains visually simple.

## Check-In

- On planned Flex Days, first question changes to “How did today go?”
- Options are “Used Flex Day” and “Stayed on plan.”
- Saving “Used Flex Day” stores `dietStatus = flex`.
- Saving “Stayed on plan” stores `dietStatus = yes`.
- Movement and optional weight still work.
- Saving weight still upserts `WeightEntry`.

## Progress

- Consistency excludes saved Flex Days from eligible days.
- Copy changes to mention non-flex days when applicable.
- Weight chart is unchanged.

## Goals

- Diet goals count `yes` days.
- Flex Days do not count as completed diet days.
- Flex Days do not count as missed days.
- If planned Flex Days exist this week, diet goal card can mention them.

## History

- Saved Flex Days render with lavender/soft purple state.
- Legend includes Flex Day.
- Blue weigh-in dot can still appear on Flex Days.

## Streaks

- Flex Days pause the streak.
- Flex Days do not break the streak.
- `no` still breaks the streak.

## Guardrails

- Do not add social, 1v1, AI, backend, auth, calories, meals, macros, food databases, barcode scanning, or wearable sync.
- Do not make Today busy.
- Do not move the weight graph to Today.
- Do not add decorative chevrons.
- Keep copy supportive and non-shaming.

---

# Codex Implementation Prompt

Use this prompt after adding this file to the repo, ideally as:

```txt
/docs/features/FLEX_DAYS.md
```

Prompt:

```txt
Implement the Flex Days feature for WeighApp using /docs/features/FLEX_DAYS.md as the source of truth.

Before coding:
1. Read APP_STATE.md.
2. Read /docs/features/FLEX_DAYS.md.
3. Preserve the existing Phase 1 scope and guardrails.

Feature goal:
Allow users to define planned Flex Days, which are planned off-plan days that do not count as missed days and pause streaks instead of breaking them.

Implementation requirements:
- Add Flex Days settings in Profile.
- Add local persistence for Flex Days in UserProfile.
- Add a flex diet status to DailyCheckIn.
- Update Today so planned Flex Days use Flex Day copy.
- Update Check-in so planned Flex Days ask “How did today go?” with “Used Flex Day” and “Stayed on plan.”
- Update History calendar and legend with a lavender/soft purple Flex Day state.
- Update TrackerMetrics so Flex Days pause streaks and are excluded from consistency eligible days.
- Update Goals diet goal display so Flex Days do not count as completed or missed.
- Preserve WeightEntry behavior exactly: Flex Day weights still upsert WeightEntry.
- Keep UI clean and consistent with the current native SwiftUI design system.

Do not add:
- Auth
- Backend
- Social features
- 1v1 challenges
- AI coaching
- Calories
- Meals
- Macros
- Food database
- Barcode scanning
- Wearable sync

After implementing:
- Build the app for simulator.
- Summarize files changed.
- Summarize the data model changes.
- List any assumptions made.
```

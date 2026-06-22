# AGENTS.md — Weight Loss Habit Tracker App

## Product direction

This app is a personal weight-loss and habit-tracking app focused on consistency, not calorie tracking.

The core product promise is:

“Track the days that matter. Build consistency. Watch the weight trend follow.”

This is Phase 1. Do not build social features, 1v1 battles, attacks, power-ups, meal tracking, calorie tracking, macros, food databases, barcode scanning, AI coaching, wearable sync, or complex health reports.

The app should feel lightweight, supportive, calm, and motivating.

## Core app structure

Use 4 main tabs:

1. Today
2. Progress
3. Goals
4. History

The visual style should follow the approved mockups:
- Clean modern mobile UI
- Light background
- Soft mint / green palette
- Rounded cards
- Subtle shadows
- Large readable typography
- Minimal icons
- Friendly tone
- Plenty of whitespace
- No dense dashboards
- No clinical fitness-app look

## Today tab

This is the normal everyday/default home state.

The Today screen should NOT show the full check-in form. It should show a calm summary state:
- Header: “Today”
- Subtitle: “Small steps count.”
- Compact check-in card when the check-in window is active, or briefly after a save/edit
- Optional pinned Challenge card when the user pins one active Challenge
- Weekly Goal card: “3 / 5 diet days completed”
- Current Progress card with current weight, total lost, and goal weight
- Streak card with current streak and best streak
- Small supportive message card
- Bottom-trailing “Log weight” FAB for standalone weigh-ins

Do not show the weight graph on the Today screen.

Normal pending check-in copy:
- Title: “Today’s check-in”
- Status: “Ready when you are”
- Primary button: “Start check-in”

Planned Flex Day pending copy:
- Title: “Flex Day”
- Status: “Planned break”
- Primary button: “Check in”

The check-in card is time-aware:
- If reminders are enabled, pending check-in appears 2 hours before the selected reminder time.
- If reminders are off, pending check-in appears at 12:00 PM.
- Saved check-in confirmation stays visible for 2 hours after save/edit, then hides.

## Check-in screen/state

The check-in form appears only after tapping “Start check-in”.

It should ask only:
1. “Did you follow your diet today?” with options: Yes, Mostly, No
2. “Did you move today?” with options: Yes, No
3. Optional weight log

Then show a primary button:
“Save check-in”

Keep this screen minimal. No calories, macros, meals, notes, or complex forms.

On planned Flex Days, the diet question changes to “How did today go?” with:
- “Used Flex Day”
- “Stayed on plan”

Flex Day check-ins save `dietStatus = flex`; they pause streaks and do not count as missed or completed diet days.

## Progress tab

The Progress screen can show:
- Current weight
- Total lost
- Goal weight
- Weight trend graph with true `6W`, `3M`, and `All` ranges
- Body measurement trends for chest, waist, and hips
- Consistency percentage
- Achievements summary
- Supportive insight message

The graph belongs here, not on the Today screen.

Progress also has the “Log weight” FAB. Standalone weight logs update weight trend, current/latest weight, History weigh-in dots, weigh-in goals, and achievements without creating a daily check-in.

## Goals tab

The Goals screen should show:
- Active goals
- Goal cards with simple progress bars
- Challenges section above Core goals
- Completed goals
- Create goal button

Phase 1 goal types:
- Follow diet X days per week
- Reach target weight
- Move X days per week
- Log weight X times per week

Challenges are separate from recurring goals and achievements. They are local, user-created, time-boxed focus periods such as “First 30 days” or “First 5 kg.” V1 supports:
- Check-in days
- Weight loss

Challenge cards use a circular progress ring on the left. One active Challenge can be pinned to Today.

## History tab

The History screen should show:
- Monthly calendar view
- Green days: on-plan
- Yellow days: mostly
- Gray days: missed
- Lavender days: saved Flex Days
- Blue dot: weigh-in logged
- Simple legend
- Monthly summary stats

## Tone and copy rules

The app should never shame the user.

Use supportive language:
- “Small steps count.”
- “Keep showing up for you.”
- “You’re building a healthier future.”
- “Missed days happen. Complete today and keep the week alive.”
- “Your weekly average matters more than one weigh-in.”

Avoid:
- “Failed”
- “Bad”
- “Cheat”
- “Punishment”
- “Fat”
- “Burn calories”
- “You lost control”

Use “Flex Day” instead of “cheat day.”
Use “Finished” instead of “failed” for incomplete ended Challenges.

## Implementation priorities

Prioritize:
- Clean UI fidelity
- Simple state management
- Minimal data model
- Fast daily check-in
- Consistent spacing and typography
- Good empty states
- Mobile-first layout

Avoid:
- Overbuilding
- Adding unrequested features
- Making dashboards too busy
- Adding nutrition/calorie complexity
- Changing the product scope without asking

## Data model suggestion

Use a simple model:

DailyCheckIn:
- id
- date
- dietStatus: “yes” | “mostly” | “no” | “flex”
- moved: boolean
- weight: number | null
- createdAt
- updatedAt

WeightEntry:
- id
- date
- weight
- unit
- createdAt
- updatedAt

BodyMeasurementEntry:
- id
- date
- chest: number | null
- waist: number | null
- hips: number | null
- unit: “cm” | “in”
- createdAt
- updatedAt

Goal:
- id
- type: “diet_days” | “weight_target” | “movement_days” | “weigh_ins”
- title
- targetValue
- currentValue
- period: “week” | “month” | “custom”
- status: “active” | “completed”
- createdAt
- completedAt

UserProgress:
- startingWeight
- currentWeight
- goalWeight
- unit: “kg” | “lb”
- currentStreak
- bestStreak

Challenge:
- title
- kind: “check_in_days” | “weight_loss”
- startDate
- endDate
- targetValue
- baselineWeight
- unit
- isPinned
- completedAt
- archivedAt

EarnedAchievement:
- key
- earnedAt
- createdAt

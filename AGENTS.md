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

The Today screen should NOT show the full check-in form. It should only show:
- Header: “Today”
- Subtitle: “Small steps count.”
- Compact card: “Today’s check-in”
- Status: “Ready when you are”
- Primary button: “Start check-in”
- Weekly Goal card: “3 / 5 diet days completed”
- Current Progress card with current weight, total lost, and goal weight
- Streak card with current streak and best streak
- Small supportive message card

Do not show the weight graph on the Today screen.

## Check-in screen/state

The check-in form appears only after tapping “Start check-in”.

It should ask only:
1. “Did you follow your diet today?” with options: Yes, Mostly, No
2. “Did you move today?” with options: Yes, No
3. Optional weight log

Then show a primary button:
“Save check-in”

Keep this screen minimal. No calories, macros, meals, notes, or complex forms.

## Progress tab

The Progress screen can show:
- Current weight
- Total lost
- Goal weight
- Weight trend graph
- Consistency percentage
- Supportive insight message

The graph belongs here, not on the Today screen.

## Goals tab

The Goals screen should show:
- Active goals
- Goal cards with simple progress bars
- Completed goals
- Create goal button

Phase 1 goal types:
- Follow diet X days per week
- Reach target weight
- Move X days per week
- Log weight X times per week

## History tab

The History screen should show:
- Monthly calendar view
- Green days: on-plan
- Yellow days: mostly
- Gray days: missed
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
- dietStatus: “yes” | “mostly” | “no”
- moved: boolean
- weight: number | null
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
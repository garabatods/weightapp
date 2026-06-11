import PhotosUI
import SwiftUI
import UIKit

struct ProfileSetupValues {
    let displayName: String?
    let unit: String
    let startingWeight: Double
    let currentWeight: Double
    let goalWeight: Double
    let weeklyDietTarget: Int
    let weeklyMovementTarget: Int
    let weeklyWeighInTarget: Int
    let checkInReminderEnabled: Bool
    let checkInReminderHour: Int
    let checkInReminderMinute: Int
    let flexDaysEnabled: Bool
    let flexWeekdayMask: Int
}

typealias SetupValues = ProfileSetupValues

enum ProfileSetupValidation {
    static func values(
        displayName: String? = nil,
        unit: String,
        startingWeight: String,
        currentWeight: String,
        goalWeight: String,
        weeklyDietTarget: Int,
        weeklyMovementTarget: Int,
        weeklyWeighInTarget: Int,
        checkInReminderEnabled: Bool = false,
        checkInReminderHour: Int = CheckInReminderDefaults.hour,
        checkInReminderMinute: Int = CheckInReminderDefaults.minute,
        flexDaysEnabled: Bool = false,
        flexWeekdayMask: Int = 0
    ) -> (values: ProfileSetupValues?, message: String?) {
        let trimmedUnit = unit == "lb" ? "lb" : "kg"
        guard
            let starting = Double(startingWeight),
            let current = Double(currentWeight),
            let goal = Double(goalWeight),
            starting > 0,
            current > 0,
            goal > 0
        else {
            return (nil, "Enter weights greater than zero.")
        }

        guard (1...7).contains(weeklyDietTarget),
              (1...7).contains(weeklyMovementTarget),
              (1...7).contains(weeklyWeighInTarget)
        else {
            return (nil, "Weekly targets should be between 1 and 7.")
        }

        guard (0...23).contains(checkInReminderHour),
              (0...59).contains(checkInReminderMinute)
        else {
            return (nil, "Choose a valid reminder time.")
        }

        return (
            ProfileSetupValues(
                displayName: displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                unit: trimmedUnit,
                startingWeight: starting,
                currentWeight: current,
                goalWeight: goal,
                weeklyDietTarget: weeklyDietTarget,
                weeklyMovementTarget: weeklyMovementTarget,
                weeklyWeighInTarget: weeklyWeighInTarget,
                checkInReminderEnabled: checkInReminderEnabled,
                checkInReminderHour: checkInReminderHour,
                checkInReminderMinute: checkInReminderMinute,
                flexDaysEnabled: flexDaysEnabled,
                flexWeekdayMask: flexDaysEnabled ? flexWeekdayMask : 0
            ),
            nil
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

struct GoalTargetValues {
    let weeklyDietTarget: Int
    let weeklyMovementTarget: Int
    let weeklyWeighInTarget: Int
    let goalWeight: Double
}

struct ProfileBaselineValues {
    let startingWeight: Double
    let currentWeight: Double
    let goalWeight: Double
}

struct ProfileIdentityValues {
    let displayName: String?
}

struct CheckInReminderValues {
    let enabled: Bool
    let hour: Int
    let minute: Int
}

struct FlexDaysPreferenceValues {
    let enabled: Bool
    let weekdayMask: Int
}

enum WeightUnitConverter {
    static let supportedUnits = ["kg", "lb"]
    private static let poundsPerKilogram = 2.2046226218

    static func converted(_ value: Double, from oldUnit: String, to newUnit: String) -> Double {
        guard oldUnit != newUnit else { return value }
        if oldUnit == "kg", newUnit == "lb" {
            return value * poundsPerKilogram
        }
        if oldUnit == "lb", newUnit == "kg" {
            return value / poundsPerKilogram
        }
        return value
    }
}

enum WeightInputRules {
    static func realisticRange(for unit: String) -> ClosedRange<Double> {
        unit == "lb" ? 66...880 : 30...400
    }

    static func rangeText(for unit: String) -> String {
        unit == "lb" ? "66 and 880 lb" : "30 and 400 kg"
    }
}

struct GoalFormValues {
    let title: String
    let type: GoalType
    let targetValue: Double
    let period: GoalPeriod
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case baseline
    case targets
    case flexDays

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .baseline: "Your starting point"
        case .targets: "Weekly targets"
        case .flexDays: "Flex Days"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: "Small steps count."
        case .baseline: "Set your baseline."
        case .targets: "Choose a steady rhythm."
        case .flexDays: "Plan room for real life."
        }
    }
}

struct OnboardingScreen: View {
    let onComplete: (SetupValues) -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var displayName = ""
    @State private var unit = "kg"
    @State private var startingWeight = "108.0"
    @State private var currentWeight = "106.8"
    @State private var goalWeight = "95.0"
    @State private var weeklyDietTarget = 5
    @State private var weeklyMovementTarget = 3
    @State private var weeklyWeighInTarget = 3
    @State private var checkInReminderEnabled = false
    @State private var checkInReminderTime = CheckInReminderDefaults.date()
    @State private var flexDaysEnabled = false
    @State private var flexWeekdayMask = 0
    @State private var validationMessage = ""

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            AppScroll {
                onboardingHeader
                OnboardingStepIndicator(currentStep: step.rawValue, totalSteps: OnboardingStep.allCases.count)

                currentStepContent

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: step == .flexDays ? "Start tracking" : "Continue") {
                    advance()
                }
            }
        }
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .baseline:
            baselineStep
        case .targets:
            targetsStep
        case .flexDays:
            flexDaysStep
        }
    }

    private var onboardingHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            if step != .welcome {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(AppTheme.mint.opacity(0.78)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(step.title)
                        .font(AppTypography.secondaryTitle)
                        .foregroundStyle(AppTheme.primaryDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                Text(step.subtitle)
                    .font(AppTypography.secondarySubtitle)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            AppCard(tint: true) {
                HStack(spacing: 14) {
                    IconBubble(symbol: "leaf.fill", tone: .success)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Track the days that matter. Build consistency. Watch the weight trend follow.")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("You’re building a healthier future.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("What should we call you?")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    SetupTextField(title: "Name", text: $displayName)
                    Text("Optional. Personal details stay on this device.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var baselineStep: some View {
        AppCard(tint: true) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weight units")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)

                Picker("Unit", selection: $unit) {
                    Text("kg").tag("kg")
                    Text("lb").tag("lb")
                }
                .pickerStyle(.segmented)
                .onChange(of: unit) { oldValue, newValue in
                    convertWeightFields(from: oldValue, to: newValue)
                }

                SetupNumberField(title: "Starting weight", text: $startingWeight, unit: unit)
                SetupNumberField(title: "Current weight", text: $currentWeight, unit: unit)
                SetupNumberField(title: "Goal weight", text: $goalWeight, unit: unit)
            }
        }
    }

    private var targetsStep: some View {
        VStack(spacing: 14) {
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly targets")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)

                    TargetStepper(title: "Diet days", value: $weeklyDietTarget, range: 1...7)
                    TargetStepper(title: "Move days", value: $weeklyMovementTarget, range: 1...7)
                    TargetStepper(title: "Weigh-ins", value: $weeklyWeighInTarget, range: 1...7)
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $checkInReminderEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-in reminder")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                            Text("A gentle reminder to wrap up your day.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(AppTheme.primary)

                    if checkInReminderEnabled {
                        Divider()
                        HStack {
                            Text("Reminder time")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            DatePicker(
                                "Reminder time",
                                selection: $checkInReminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                    }
                }
            }

            AppCard(tint: true) {
                HStack(spacing: 14) {
                    IconBubble(symbol: "calendar.badge.checkmark", tone: .success)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your weekly average matters more than one weigh-in.")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Text("Keep showing up for you.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private var flexDaysStep: some View {
        VStack(spacing: 14) {
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $flexDaysEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Flex Days")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                            Text("Plan off-days ahead of time. Flex Days do not count as missed days.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(AppTheme.primary)

                    if flexDaysEnabled {
                        Divider()
                        WeekdayPicker(mask: $flexWeekdayMask)
                    }
                }
            }

            AppCard(tint: true) {
                HStack(spacing: 14) {
                    IconBubble(symbol: "sparkles", tone: .flex)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Planned flexibility keeps the week supportive.")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Text("You can update Flex Days later in Profile.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private func advance() {
        validationMessage = ""

        switch step {
        case .welcome:
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedName.count <= 28 else {
                validationMessage = "Use 28 characters or fewer."
                return
            }
            step = .baseline
        case .baseline:
            step = .targets
        case .targets:
            step = .flexDays
        case .flexDays:
            submit()
        }
    }

    private func goBack() {
        validationMessage = ""
        guard let previousStep = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previousStep
    }

    private func submit() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let reminderTime = CheckInReminderDefaults.components(from: checkInReminderTime)
        let result = ProfileSetupValidation.values(
            displayName: trimmedName,
            unit: unit,
            startingWeight: startingWeight,
            currentWeight: currentWeight,
            goalWeight: goalWeight,
            weeklyDietTarget: weeklyDietTarget,
            weeklyMovementTarget: weeklyMovementTarget,
            weeklyWeighInTarget: weeklyWeighInTarget,
            checkInReminderEnabled: checkInReminderEnabled,
            checkInReminderHour: reminderTime.hour,
            checkInReminderMinute: reminderTime.minute,
            flexDaysEnabled: flexDaysEnabled,
            flexWeekdayMask: flexWeekdayMask
        )

        if let values = result.values {
            onComplete(values)
        } else {
            validationMessage = result.message ?? "Check your numbers and try again."
            if result.message == "Enter weights greater than zero." {
                step = .baseline
            }
        }
    }

    private func convertWeightFields(from oldUnit: String, to newUnit: String) {
        guard oldUnit != newUnit else { return }
        startingWeight = convertedWeightText(startingWeight, from: oldUnit, to: newUnit)
        currentWeight = convertedWeightText(currentWeight, from: oldUnit, to: newUnit)
        goalWeight = convertedWeightText(goalWeight, from: oldUnit, to: newUnit)
        validationMessage = ""
    }

    private func convertedWeightText(_ text: String, from oldUnit: String, to newUnit: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return text }
        let converted = WeightUnitConverter.converted(value, from: oldUnit, to: newUnit)
        return String(format: "%.1f", converted)
    }
}

struct OnboardingStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? AppTheme.primary : AppTheme.track)
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
    }
}

struct TodayScreen: View {
    let metrics: TrackerMetrics
    let onProfileTap: () -> Void
    let onStartCheckIn: () -> Void

    private var progress: UserProgress {
        metrics.progress
    }

    private var checkInStatusText: String {
        guard metrics.todayCheckIn == nil else { return "Saved for today" }
        if metrics.isTodayPlannedFlexDay {
            return "Planned break. No pressure - keep it intentional."
        }
        let reminderTime = CheckInReminderDefaults.date(
            hour: metrics.profile.checkInReminderHour,
            minute: metrics.profile.checkInReminderMinute
        )
        return Date() >= reminderTime ? "Ready to wrap up today." : "Come back when your day winds down."
    }

    private var checkInCardTitle: String {
        if metrics.todayCheckIn?.dietStatus == .flex {
            return "Flex Day saved"
        }
        if metrics.todayCheckIn == nil && metrics.isTodayPlannedFlexDay {
            return "Today is a Flex Day"
        }
        return "Today’s check-in"
    }

    private var checkInCardStatus: String {
        if metrics.todayCheckIn?.dietStatus == .flex {
            return "Your streak is paused, not broken."
        }
        return checkInStatusText
    }

    private var checkInActionTitle: String {
        metrics.todayCheckIn == nil && metrics.isTodayPlannedFlexDay ? "Quick check-in" : "Start check-in"
    }

    var body: some View {
        AppScroll {
            AppHeader(title: "Today", subtitle: "Small steps count.", profileImageData: metrics.profile.profileImageData, onProfileTap: onProfileTap)
            CheckInCard(
                hasCheckIn: metrics.todayCheckIn != nil,
                title: checkInCardTitle,
                statusText: checkInCardStatus,
                helperText: metrics.todayCheckIn == nil && metrics.isTodayPlannedFlexDay ? "Flex Days do not count as missed days." : nil,
                actionTitle: checkInActionTitle,
                iconSymbol: metrics.isTodayPlannedFlexDay || metrics.todayCheckIn?.dietStatus == .flex ? "sparkles" : "target",
                iconTone: metrics.isTodayPlannedFlexDay || metrics.todayCheckIn?.dietStatus == .flex ? .flex : .primary,
                onStart: onStartCheckIn
            )

            AppCard {
                HStack(alignment: .top, spacing: 14) {
                    IconBubble(symbol: "flag.fill", tone: .primary)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekly Goal")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(metrics.weeklyDietCount)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.primary)
                            Text("/ \(metrics.profile.weeklyDietTarget)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Text("diet days completed")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                        if metrics.plannedFlexDaysThisWeek > 0 {
                            Text("\(metrics.plannedFlexDaysThisWeek) Flex Days planned this week")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.lavender)
                        }
                        ProgressBar(
                            value: Double(metrics.weeklyDietCount),
                            total: Double(metrics.profile.weeklyDietTarget),
                            segments: metrics.profile.weeklyDietTarget
                        )
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        IconBubble(symbol: "scalemass", tone: .neutral)
                        Text("Current Progress")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        MetricColumn(icon: nil, value: String(format: "%.1f", progress.currentWeight), unit: progress.unit, label: "Current weight", valueColor: AppTheme.primary)
                        VerticalDivider()
                        MetricColumn(icon: nil, value: String(format: "%.1f", progress.totalLost), unit: progress.unit, label: "Total lost")
                        VerticalDivider()
                        MetricColumn(icon: nil, value: String(format: "%.1f", progress.goalWeight), unit: progress.unit, label: "Goal weight")
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        IconBubble(symbol: "flame.fill", color: AppTheme.orange, background: AppTheme.orangeSoft)
                        Text("Streak")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        StreakMetric(value: progress.currentStreak, label: "Current streak")
                        VerticalDivider()
                        StreakMetric(value: progress.bestStreak, label: "Best streak")
                    }
                }
            }

            AppCard(tint: true) {
                HStack(spacing: 14) {
                    IconBubble(symbol: "leaf.fill", tone: .success)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("You’re building a healthier future.")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Text("Keep showing up for you.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "heart")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

struct CheckInScreen: View {
    let profile: UserProfile
    let existingCheckIn: DailyCheckIn?
    let onCancel: () -> Void
    let onSave: (DietStatus, Bool, Double?) -> Void
    @State private var dietStatus: DietStatus = .yes
    @State private var moved = true
    @State private var weightText = ""
    @State private var validationMessage = ""
    @FocusState private var isWeightFocused: Bool
    private let usesFlexCheckInMode: Bool

    init(
        profile: UserProfile,
        existingCheckIn: DailyCheckIn?,
        onCancel: @escaping () -> Void,
        onSave: @escaping (DietStatus, Bool, Double?) -> Void
    ) {
        self.profile = profile
        self.existingCheckIn = existingCheckIn
        self.onCancel = onCancel
        self.onSave = onSave
        let flexMode = existingCheckIn?.dietStatus == .flex || (existingCheckIn == nil && profile.isPlannedFlexDay(Date()))
        self.usesFlexCheckInMode = flexMode
        _dietStatus = State(initialValue: existingCheckIn?.dietStatus ?? (flexMode ? .flex : .yes))
        _moved = State(initialValue: existingCheckIn?.moved ?? true)
        _weightText = State(initialValue: existingCheckIn?.weight.map { String(format: "%.1f", $0) } ?? "")
    }

    var body: some View {
        AppScroll {
            SecondaryHeader(title: "Check-in", subtitle: "A quick moment for today.", onBack: cancelCheckIn)

            AppCard(tint: true) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        CompactIconBubble(symbol: "target")
                        Text(usesFlexCheckInMode ? "How did today go?" : "Did you follow your diet today?")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .allowsTightening(true)
                    }

                    VStack(spacing: 10) {
                        ForEach(dietOptions, id: \.status) { option in
                            SelectablePill(title: option.title, selected: dietStatus == option.status) {
                                let status = option.status
                                dietStatus = status
                            }
                        }
                    }
                }
            }

            AppCard(tint: true) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        movePrompt
                        Spacer(minLength: 8)
                        moveChoices
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        movePrompt
                        moveChoices
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            AppCard(tint: true) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        weightPrompt
                        Spacer(minLength: 8)
                        weightInput
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        weightPrompt
                        weightInput
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Save check-in", action: submitCheckIn)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isWeightFocused = false
                }
            }
        }
    }

    private func submitCheckIn() {
        isWeightFocused = false
        validationMessage = ""

        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWeight.isEmpty else {
            onSave(dietStatus, moved, nil)
            return
        }

        guard let weight = Double(trimmedWeight) else {
            validationMessage = "Enter a valid weight or leave it blank."
            return
        }

        guard realisticWeightRange.contains(weight) else {
            validationMessage = "Enter a weight between \(weightRangeText)."
            return
        }

        onSave(dietStatus, moved, weight)
    }

    private func cancelCheckIn() {
        isWeightFocused = false
        onCancel()
    }

    private var dietOptions: [(status: DietStatus, title: String)] {
        if usesFlexCheckInMode {
            return [(.flex, "Used Flex Day"), (.yes, "Stayed on plan")]
        }
        return DietStatus.standardOptions.map { ($0, $0.label) }
    }

    private var movePrompt: some View {
        HStack(spacing: 12) {
            CompactIconBubble(symbol: "shoeprints.fill")
            Text("Did you move today?")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .layoutPriority(1)
        }
    }

    private var moveChoices: some View {
        HStack(spacing: 8) {
            SmallChoiceButton(title: "Yes", selected: moved) {
                moved = true
            }
            SmallChoiceButton(title: "No", selected: !moved) {
                moved = false
            }
        }
    }

    private var weightPrompt: some View {
        HStack(spacing: 12) {
            CompactIconBubble(symbol: "scalemass")
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("Log weight")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppTheme.text)
                Text("(optional)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .allowsTightening(true)
            .layoutPriority(1)
        }
    }

    private var weightInput: some View {
        HStack(spacing: 8) {
            TextField("", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(AppTypography.primaryAction)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 68)
                .accessibilityLabel("Weight")
                .focused($isWeightFocused)
            Text(profile.unit)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
        )
    }

    private var realisticWeightRange: ClosedRange<Double> {
        WeightInputRules.realisticRange(for: profile.unit)
    }

    private var weightRangeText: String {
        WeightInputRules.rangeText(for: profile.unit)
    }
}

struct CompactIconBubble: View {
    let symbol: String
    var tone: IconTone = .neutral

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tone.background)
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tone.foreground)
        }
        .frame(width: 44, height: 44)
    }
}

struct ProgressScreen: View {
    let metrics: TrackerMetrics
    let onProfileTap: () -> Void
    let onAddPastWeight: () -> Void

    private var progress: UserProgress {
        metrics.progress
    }

    var body: some View {
        AppScroll {
            AppHeader(title: "Progress", subtitle: "Your trend over time.", profileImageData: metrics.profile.profileImageData, onProfileTap: onProfileTap)
            StatCard(progress: progress, showIcons: true)

            AppCard {
                VStack(alignment: .leading, spacing: 20) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: 12) {
                            weightTrendTitle
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("6 weeks")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.secondaryText)
                                InlineActionButton(title: "Add past weight", action: onAddPastWeight)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                weightTrendTitle
                                Spacer()
                                Text("6 weeks")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            InlineActionButton(title: "Add past weight", action: onAddPastWeight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    WeightTrendChart(points: metrics.trendPoints)
                        .frame(height: 260)
                }
            }

            AppCard {
                VStack(spacing: 20) {
                    HStack(spacing: 18) {
                        IconBubble(symbol: "calendar.badge.checkmark", tone: .neutral)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Consistency")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(metrics.monthlyConsistency)")
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.primary)
                                Text("%")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primary)
                            }
                            Text(metrics.hasFlexCheckInsThisMonth ? "on-plan across non-flex days" : "on-plan this month")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }

                    Divider()

                    HStack(spacing: 14) {
                        IconBubble(symbol: "leaf.fill", tone: .success)
                            .frame(width: 48, height: 48)
                        Text(metrics.monthlyEligibleCheckInCount == 0 ? "Complete a check-in when you’re ready." : "Your weekly average matters more than one weigh-in.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var weightTrendTitle: some View {
        HStack(spacing: 14) {
            IconBubble(symbol: "chart.line.uptrend.xyaxis", tone: .neutral)
            Text("Weight trend")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

struct GoalsScreen: View {
    let metrics: TrackerMetrics
    let onProfileTap: () -> Void
    let onAdjustTargets: () -> Void
    let onCreateGoal: () -> Void
    let onEditGoal: (Goal) -> Void
    let onDeleteGoal: (Goal) -> Void

    var body: some View {
        AppScroll {
            AppHeader(title: "Goals", subtitle: "Small targets, steady wins.", profileImageData: metrics.profile.profileImageData, onProfileTap: onProfileTap)

            AppCard(tint: true) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        targetsIntro
                        Spacer(minLength: 8)
                        InlineActionButton(title: "Adjust targets", action: onAdjustTargets)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        targetsIntro
                        InlineActionButton(title: "Adjust targets", action: onAdjustTargets)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            SectionTitle("Core goals")
            ForEach(metrics.coreGoalCards, id: \.goal.id) { item in
                GoalCard(goal: item.goal, mode: item.mode, isCompleted: item.isCompleted)
            }

            SectionTitle("Extra goals")
            if metrics.extraActiveGoalCards.isEmpty {
                EmptyStateCard(title: "No extra goals yet.", subtitle: "Create a small target to keep momentum visible.")
            } else {
                ForEach(metrics.extraActiveGoalCards, id: \.goal.id) { item in
                    GoalCard(
                        goal: item.goal,
                        mode: item.mode,
                        onEdit: { onEditGoal(item.goal) },
                        onDelete: { onDeleteGoal(item.goal) }
                    )
                }
            }

            PrimaryButton(title: "Create goal", systemImage: "plus.circle", action: onCreateGoal)

            SectionTitle("Completed")
            if metrics.extraCompletedGoalCards.isEmpty {
                EmptyStateCard(title: "No completed goals yet.", subtitle: "Small wins will show up here.")
            } else {
                ForEach(metrics.extraCompletedGoalCards, id: \.goal.id) { item in
                    GoalCard(
                        goal: item.goal,
                        mode: item.mode,
                        isCompleted: true,
                        onEdit: { onEditGoal(item.goal) },
                        onDelete: { onDeleteGoal(item.goal) }
                    )
                }
            }
        }
    }

    private var targetsIntro: some View {
        HStack(spacing: 14) {
            IconBubble(symbol: "target", tone: .primary)
            VStack(alignment: .leading, spacing: 5) {
                Text("Your main targets")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text("Keep the app aligned with what matters this week.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}

struct HistoryScreen: View {
    let metrics: TrackerMetrics
    let onProfileTap: () -> Void
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void

    var body: some View {
        AppScroll {
            AppHeader(title: "History", subtitle: "Your days at a glance.", profileImageData: metrics.profile.profileImageData, onProfileTap: onProfileTap)
            CalendarMonth(
                title: metrics.calendarMonthTitle,
                days: metrics.calendarDays,
                onPrevious: onPreviousMonth,
                onNext: onNextMonth
            )

            AppCard {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    LegendItem(color: AppTheme.successSoft, title: "On-plan")
                    LegendItem(color: AppTheme.yellow, title: "Mostly")
                    LegendItem(color: AppTheme.grayDay, title: "Missed")
                    LegendItem(color: AppTheme.lavenderSoft, title: "Flex Day")
                    LegendItem(color: AppTheme.blue, title: "Weigh-in logged")
                }
            }

            AppCard {
                HStack(spacing: 0) {
                    SummaryMetric(symbol: "calendar.badge.checkmark", value: "\(metrics.monthlyOnPlanCount)", label: "On-plan days\nthis month", tone: .success, valueColor: AppTheme.primary)
                    VerticalDivider()
                    SummaryMetric(symbol: "flame.fill", value: "\(metrics.progress.currentStreak)", label: "Day streak\ncurrent", tone: .warning, valueColor: AppTheme.orange)
                    VerticalDivider()
                    SummaryMetric(symbol: "scalemass", value: "\(metrics.monthlyWeighInCount)", label: "Weigh-ins\nthis month", tone: .info, valueColor: AppTheme.blue)
                }
            }
        }
    }
}

private enum ProfileEditDestination: String, Identifiable {
    case identity
    case baseline
    case targets
    case units
    case reminder
    case flexDays

    var id: String { rawValue }
}

struct ProfileSettingsScreen: View {
    let metrics: TrackerMetrics
    let onClose: () -> Void
    let onSaveIdentity: (ProfileIdentityValues) -> Void
    let onSaveProfileImage: (Data) -> Void
    let onRemoveProfileImage: () -> Void
    let onSaveBaseline: (ProfileBaselineValues) -> Void
    let onSaveTargets: (GoalTargetValues) -> Void
    let onSaveUnit: (String) -> Void
    let onSaveReminder: (CheckInReminderValues) -> Void
    let onSaveFlexDays: (FlexDaysPreferenceValues) -> Void
    let onResetData: () -> Void

    @State private var editDestination: ProfileEditDestination?
    @State private var isConfirmingReset = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingPhotoOptions = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false
    @State private var isShowingCameraUnavailable = false

    private var progress: UserProgress {
        metrics.progress
    }

    private var displayName: String {
        let trimmedName = (metrics.profile.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Your profile" : trimmedName
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            AppScroll {
                SecondaryHeader(title: "Profile", subtitle: "Your plan, your pace.", onBack: onClose)

                AppCard(tint: true) {
                    HStack(alignment: .center, spacing: 12) {
                        profilePhoto

                        identityText
                        .layoutPriority(1)

                        Spacer(minLength: 8)
                        identityEditButton
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Today’s baseline", destination: .baseline)

                        LazyVGrid(columns: profileGridColumns, spacing: 12) {
                            ProfileMetricTile(label: "Current weight", value: weightText(progress.currentWeight))
                            ProfileMetricTile(label: "Starting weight", value: weightText(progress.startingWeight))
                            ProfileMetricTile(label: "Goal weight", value: weightText(progress.goalWeight))
                            ProfileMetricTile(label: "Total lost", value: weightText(progress.totalLost))
                        }
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Your targets", destination: .targets)

                        ProfileSummaryRow(symbol: "flag.fill", title: "Diet days", value: "\(metrics.profile.weeklyDietTarget) / week")
                        ProfileSummaryRow(symbol: "shoeprints.fill", title: "Move days", value: "\(metrics.profile.weeklyMovementTarget) / week")
                        ProfileSummaryRow(symbol: "calendar.badge.checkmark", title: "Weigh-ins", value: "\(metrics.profile.weeklyWeighInTarget) / week")
                        ProfileSummaryRow(symbol: "scalemass", title: "Goal weight", value: weightText(progress.goalWeight))
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ProfileSectionHeader(title: "Preferences")
                        ProfileActionRow(symbol: "textformat.size", title: "Weight units", value: progress.unit) {
                            editDestination = .units
                        }
                        ProfileActionRow(symbol: "bell.fill", title: "Check-in reminder", value: reminderSummary) {
                            editDestination = .reminder
                        }
                        ProfileActionRow(symbol: "sparkles", title: "Flex Days", value: metrics.profile.flexDaysSummary) {
                            editDestination = .flexDays
                        }
                        Text("Units are used across cards, charts, and check-ins. Changing units converts saved weights.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ProfileSectionHeader(title: "Data & privacy")

                        Text("Your profile, goals, and check-ins stay on this device.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(role: .destructive) {
                            isConfirmingReset = true
                        } label: {
                            Text("Reset local data")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.destructive)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.destructiveSoft)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(item: $editDestination) { destination in
            switch destination {
            case .identity:
                ProfileIdentitySheet(profile: metrics.profile, onSave: onSaveIdentity, onRemovePhoto: onRemoveProfileImage)
                    .presentationDetents([.height(380)])
                    .presentationDragIndicator(.visible)
            case .baseline:
                ProfileBaselineSheet(profile: metrics.profile, onSave: onSaveBaseline)
                    .presentationDetents([.height(390)])
                    .presentationDragIndicator(.visible)
            case .targets:
                AdjustTargetsSheet(profile: metrics.profile, onSave: onSaveTargets)
                    .presentationDetents([.height(560)])
                    .presentationDragIndicator(.visible)
            case .units:
                UnitPreferenceSheet(profile: metrics.profile, onSave: onSaveUnit)
                    .presentationDetents([.height(290)])
                    .presentationDragIndicator(.visible)
            case .reminder:
                CheckInReminderSheet(profile: metrics.profile, onSave: onSaveReminder)
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            case .flexDays:
                FlexDaysPreferenceSheet(profile: metrics.profile, onSave: onSaveFlexDays)
                    .presentationDetents([.height(430)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            saveSelectedPhoto(newItem)
        }
        .photosPicker(isPresented: $isShowingPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .sheet(isPresented: $isShowingCamera) {
            CameraImagePicker { imageData in
                onSaveProfileImage(imageData)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingPhotoOptions) {
            ProfilePhotoOptionsSheet(
                hasPhoto: metrics.profile.profileImageData != nil,
                onTakePhoto: {
                    openPhotoAction {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            isShowingCamera = true
                        } else {
                            isShowingCameraUnavailable = true
                        }
                    }
                },
                onChoosePhoto: {
                    openPhotoAction {
                        isShowingPhotoLibrary = true
                    }
                },
                onRemovePhoto: {
                    onRemoveProfileImage()
                    isShowingPhotoOptions = false
                }
            )
            .presentationDetents([.height(metrics.profile.profileImageData == nil ? 250 : 310)])
            .presentationDragIndicator(.visible)
        }
        .alert("Reset local data?", isPresented: $isConfirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset local data", role: .destructive) {
                onResetData()
            }
        } message: {
            Text("This clears your profile, goals, and check-ins from this device.")
        }
        .alert("Camera unavailable", isPresented: $isShowingCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device cannot take a photo right now.")
        }
    }

    private var profilePhoto: some View {
        let imageData = metrics.profile.profileImageData
        let accessibilityTitle = imageData == nil ? "Add profile photo" : "Change profile photo"

        return Button {
            isShowingPhotoOptions = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatar(imageData: imageData, size: 58)
                Image(systemName: "camera.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 21, height: 21)
                    .background(Circle().fill(AppTheme.primary))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }

    private var identityText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(displayName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text("Personal details stay on this device.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
        }
    }

    private var identityEditButton: some View {
        Button {
            editDestination = .identity
        } label: {
            Image(systemName: "pencil")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(.white)
                        .overlay(Circle().stroke(AppTheme.primary.opacity(0.24), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit profile name")
    }

    private var profileGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private func weightText(_ value: Double) -> String {
        "\(String(format: "%.1f", value)) \(progress.unit)"
    }

    private var reminderSummary: String {
        guard metrics.profile.checkInReminderEnabled else { return "Off" }
        return CheckInReminderDefaults.timeText(
            hour: metrics.profile.checkInReminderHour,
            minute: metrics.profile.checkInReminderMinute
        )
    }

    private func sectionHeader(title: String, destination: ProfileEditDestination) -> some View {
        ProfileSectionHeader(title: title) {
            profileActionButton(title: "Edit", destination: destination)
        }
    }

    private func profileActionButton(title: String, destination: ProfileEditDestination) -> some View {
        Button {
            editDestination = destination
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(.white)
                        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.28), lineWidth: 1))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func saveSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let imageData = ProfileImageProcessor.normalizedImageData(from: data)
            else { return }

            await MainActor.run {
                onSaveProfileImage(imageData)
                selectedPhotoItem = nil
            }
        }
    }

    private func openPhotoAction(_ action: @escaping () -> Void) {
        isShowingPhotoOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            action()
        }
    }

}

enum ProfileImageProcessor {
    static func normalizedImageData(from data: Data) -> Data? {
        guard let source = UIImage(data: data) else { return nil }
        return normalizedImageData(from: source)
    }

    static func normalizedImageData(from source: UIImage) -> Data? {
        let maxSide: CGFloat = 512
        let longestSide = max(source.size.width, source.size.height)
        let scale = min(maxSide / longestSide, 1)
        let targetSize = CGSize(width: source.size.width * scale, height: source.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.82)
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImageData: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = ProfileImageProcessor.normalizedImageData(from: image) {
                parent.onImageData(imageData)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ProfilePhotoOptionsSheet: View {
    let hasPhoto: Bool
    let onTakePhoto: () -> Void
    let onChoosePhoto: () -> Void
    let onRemovePhoto: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeader(title: "Profile photo", onClose: { dismiss() })
                    .padding(.horizontal, 18)

                AppCard {
                    VStack(spacing: 2) {
                        PhotoOptionRow(symbol: "camera.fill", title: "Take photo", action: onTakePhoto)
                        Divider()
                            .padding(.leading, 52)
                        PhotoOptionRow(
                            symbol: "photo.fill",
                            title: hasPhoto ? "Choose another photo" : "Choose photo",
                            action: onChoosePhoto
                        )

                        if hasPhoto {
                            Divider()
                                .padding(.leading, 52)
                            PhotoOptionRow(
                                symbol: "trash.fill",
                                title: "Remove photo",
                                role: .destructive,
                                action: onRemovePhoto
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer(minLength: 0)
            }
        }
    }
}

struct PhotoOptionRow: View {
    let symbol: String
    let title: String
    var role: ButtonRole?
    let action: () -> Void

    private var foreground: Color {
        role == .destructive ? AppTheme.destructive : AppTheme.text
    }

    private var iconTone: IconTone {
        role == .destructive ? .warning : .neutral
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 12) {
                CompactIconBubble(symbol: symbol, tone: iconTone)
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct ProfileMetricTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
        )
    }
}

struct ProfileSectionHeader<Action: View>: View {
    let title: String
    @ViewBuilder let action: Action

    init(title: String, @ViewBuilder action: () -> Action) {
        self.title = title
        self.action = action()
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(AppTheme.primary)
                .frame(width: 4, height: 24)

            Text(title)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .layoutPriority(1)

            Spacer(minLength: 8)

            action
        }
    }
}

extension ProfileSectionHeader where Action == EmptyView {
    init(title: String) {
        self.title = title
        self.action = EmptyView()
    }
}

struct ProfileSummaryRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            CompactIconBubble(symbol: symbol)
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

struct ProfileActionRow: View {
    let symbol: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CompactIconBubble(symbol: symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Button("Edit", action: action)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(.white)
                        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.28), lineWidth: 1))
                )
                .buttonStyle(.plain)
        }
    }
}

struct ProfileIdentitySheet: View {
    let profile: UserProfile
    let onSave: (ProfileIdentityValues) -> Void
    let onRemovePhoto: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var validationMessage = ""
    @State private var hasProfilePhoto: Bool

    init(
        profile: UserProfile,
        onSave: @escaping (ProfileIdentityValues) -> Void,
        onRemovePhoto: @escaping () -> Void
    ) {
        self.profile = profile
        self.onSave = onSave
        self.onRemovePhoto = onRemovePhoto
        _displayName = State(initialValue: profile.displayName ?? "")
        _hasProfilePhoto = State(initialValue: profile.profileImageData != nil)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Edit name", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        SetupTextField(title: "Name", text: $displayName)
                        Text("This is local personalization only.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)

                        if hasProfilePhoto {
                            Button(role: .destructive) {
                                onRemovePhoto()
                                hasProfilePhoto = false
                            } label: {
                                Text("Remove photo")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.destructive)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(AppTheme.destructiveSoft)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } footer: {
                PrimaryButton(title: "Save name") {
                    submit()
                }
            }
        }
    }

    private func submit() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 28 else {
            validationMessage = "Use 28 characters or fewer."
            return
        }

        onSave(ProfileIdentityValues(displayName: trimmed.isEmpty ? nil : trimmed))
        dismiss()
    }
}

struct ProfileBaselineSheet: View {
    let profile: UserProfile
    let onSave: (ProfileBaselineValues) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startingWeight: String
    @State private var currentWeight: String
    @State private var goalWeight: String
    @State private var validationMessage = ""

    init(profile: UserProfile, onSave: @escaping (ProfileBaselineValues) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _startingWeight = State(initialValue: String(format: "%.1f", profile.startingWeight))
        _currentWeight = State(initialValue: String(format: "%.1f", profile.currentWeight))
        _goalWeight = State(initialValue: String(format: "%.1f", profile.goalWeight))
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Edit weights", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        SetupNumberField(title: "Current weight", text: $currentWeight, unit: profile.unit)
                        SetupNumberField(title: "Starting weight", text: $startingWeight, unit: profile.unit)
                        SetupNumberField(title: "Goal weight", text: $goalWeight, unit: profile.unit)
                    }
                }

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } footer: {
                PrimaryButton(title: "Save weights") {
                    submit()
                }
            }
        }
    }

    private func submit() {
        guard
            let starting = Double(startingWeight),
            let current = Double(currentWeight),
            let goal = Double(goalWeight),
            starting > 0,
            current > 0,
            goal > 0
        else {
            validationMessage = "Enter weights greater than zero."
            return
        }

        onSave(
            ProfileBaselineValues(
                startingWeight: starting,
                currentWeight: current,
                goalWeight: goal
            )
        )
        dismiss()
    }
}

struct UnitPreferenceSheet: View {
    let profile: UserProfile
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var unit: String

    init(profile: UserProfile, onSave: @escaping (String) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _unit = State(initialValue: profile.unit)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Units", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Weight units", selection: $unit) {
                            ForEach(WeightUnitConverter.supportedUnits, id: \.self) { value in
                                Text(value).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 12) {
                            CompactIconBubble(symbol: "arrow.left.arrow.right")
                            Text("Changing units converts saved weights, check-ins, and weight goals.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } footer: {
                PrimaryButton(title: "Save units") {
                    onSave(unit)
                    dismiss()
                }
            }
        }
    }
}

struct CheckInReminderSheet: View {
    let profile: UserProfile
    let onSave: (CheckInReminderValues) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled: Bool
    @State private var reminderTime: Date

    init(profile: UserProfile, onSave: @escaping (CheckInReminderValues) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _isEnabled = State(initialValue: profile.checkInReminderEnabled)
        _reminderTime = State(
            initialValue: CheckInReminderDefaults.date(
                hour: profile.checkInReminderHour,
                minute: profile.checkInReminderMinute
            )
        )
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Check-in reminder", onClose: { dismiss() }) {
                AppCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $isEnabled) {
                            Text("Check-in reminder")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                        }
                        .tint(AppTheme.primary)

                        Text("A gentle reminder to wrap up your day.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if isEnabled {
                            Divider()
                            HStack {
                                Text("Reminder time")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                        }
                    }
                }
            } footer: {
                PrimaryButton(title: "Save reminder") {
                    let components = CheckInReminderDefaults.components(from: reminderTime)
                    onSave(
                        CheckInReminderValues(
                            enabled: isEnabled,
                            hour: components.hour,
                            minute: components.minute
                        )
                    )
                    dismiss()
                }
            }
        }
    }
}

struct FlexDaysPreferenceSheet: View {
    let profile: UserProfile
    let onSave: (FlexDaysPreferenceValues) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled: Bool
    @State private var weekdayMask: Int

    init(profile: UserProfile, onSave: @escaping (FlexDaysPreferenceValues) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _isEnabled = State(initialValue: profile.flexDaysEnabled)
        _weekdayMask = State(initialValue: profile.flexWeekdayMask)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Flex Days", onClose: { dismiss() }) {
                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $isEnabled) {
                            Text("Enable Flex Days")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                        }
                        .tint(AppTheme.primary)

                        Text("Plan off-days ahead of time. Flex Days do not count as missed days.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if isEnabled {
                            Divider()
                            WeekdayPicker(mask: $weekdayMask)
                        }
                    }
                }
            } footer: {
                PrimaryButton(title: "Save Flex Days") {
                    onSave(
                        FlexDaysPreferenceValues(
                            enabled: isEnabled,
                            weekdayMask: isEnabled ? weekdayMask : 0
                        )
                    )
                    dismiss()
                }
            }
        }
    }
}

struct AddWeightEntrySheet: View {
    let profile: UserProfile
    let onSave: (Date, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var entryDate = Date()
    @State private var weightText: String
    @State private var validationMessage = ""

    init(profile: UserProfile, onSave: @escaping (Date, Double) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _weightText = State(initialValue: String(format: "%.1f", profile.currentWeight))
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Add past weight", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Date")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            DatePicker(
                                "Date",
                                selection: $entryDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }

                        SetupNumberField(title: "Weight", text: $weightText, unit: profile.unit)
                    }
                }

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } footer: {
                PrimaryButton(title: "Save weight") {
                    submit()
                }
            }
        }
    }

    private func submit() {
        validationMessage = ""
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let weight = Double(trimmedWeight) else {
            validationMessage = "Enter a valid weight."
            return
        }

        guard WeightInputRules.realisticRange(for: profile.unit).contains(weight) else {
            validationMessage = "Enter a weight between \(WeightInputRules.rangeText(for: profile.unit))."
            return
        }

        onSave(entryDate, weight)
        dismiss()
    }
}

struct AppScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    content
                }
                .frame(width: max(proxy.size.width - 36, 0))
                .padding(.horizontal, 18)
                .padding(.bottom, 74)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

struct SheetScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let bottomPadding = max(proxy.safeAreaInsets.bottom + 20, 44)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    content
                }
                .frame(width: max(proxy.size.width - 36, 0))
                .padding(.horizontal, 18)
                .padding(.bottom, bottomPadding)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

struct SheetScaffold<Content: View, Footer: View>: View {
    let title: String
    let onClose: () -> Void
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                SheetHeader(title: title, onClose: onClose)
                    .padding(.horizontal, 18)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        content
                    }
                    .frame(width: max(proxy.size.width - 36, 0))
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.immediately)

                footer
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 10, 22))
            }
        }
    }
}

struct SheetHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Color.clear
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)

            Spacer(minLength: 8)

            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppTheme.mint.opacity(0.78)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.top, 12)
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        AppCard(tint: true) {
            HStack(spacing: 14) {
                IconBubble(symbol: "leaf.fill", tone: .success)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InlineActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(.white)
                        .overlay(Capsule().stroke(AppTheme.primary.opacity(0.28), lineWidth: 1))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct SetupTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)
            TextField("", text: $text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.divider, lineWidth: 1)
                        )
                )
        }
    }
}

struct SetupNumberField: View {
    let title: String
    @Binding var text: String
    let unit: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)
            Spacer()
            HStack(spacing: 8) {
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 82)
                Text(unit)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            )
        }
    }
}

struct TargetStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }
}

struct WeekdayPicker: View {
    @Binding var mask: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flex weekdays")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.text)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(FlexWeekday.allCases) { weekday in
                    Button {
                        toggle(weekday)
                    } label: {
                        Text(weekday.shortLabel)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected(weekday) ? .white : AppTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected(weekday) ? AppTheme.lavender : .white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected(weekday) ? AppTheme.lavender : AppTheme.divider, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(weekday.shortLabel) Flex Day")
                }
            }
        }
    }

    private func isSelected(_ weekday: FlexWeekday) -> Bool {
        mask & weekday.bit != 0
    }

    private func toggle(_ weekday: FlexWeekday) {
        if isSelected(weekday) {
            mask &= ~weekday.bit
        } else {
            mask |= weekday.bit
        }
    }
}

struct AdjustTargetsSheet: View {
    let profile: UserProfile
    let onSave: (GoalTargetValues) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weeklyDietTarget: Int
    @State private var weeklyMovementTarget: Int
    @State private var weeklyWeighInTarget: Int
    @State private var goalWeight: String
    @State private var validationMessage = ""

    init(profile: UserProfile, onSave: @escaping (GoalTargetValues) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _weeklyDietTarget = State(initialValue: profile.weeklyDietTarget)
        _weeklyMovementTarget = State(initialValue: profile.weeklyMovementTarget)
        _weeklyWeighInTarget = State(initialValue: profile.weeklyWeighInTarget)
        _goalWeight = State(initialValue: String(format: "%.1f", profile.goalWeight))
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: "Adjust targets", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly targets")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppTheme.text)

                        TargetStepper(title: "Diet days", value: $weeklyDietTarget, range: 1...7)
                        TargetStepper(title: "Move days", value: $weeklyMovementTarget, range: 1...7)
                        TargetStepper(title: "Weigh-ins", value: $weeklyWeighInTarget, range: 1...7)
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weight target")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppTheme.text)

                        SetupNumberField(title: "Goal weight", text: $goalWeight, unit: profile.unit)
                    }
                }

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } footer: {
                PrimaryButton(title: "Save targets") {
                    guard let parsedGoal = Double(goalWeight), parsedGoal > 0 else {
                        validationMessage = "Enter a target weight greater than zero."
                        return
                    }

                    onSave(
                        GoalTargetValues(
                            weeklyDietTarget: weeklyDietTarget,
                            weeklyMovementTarget: weeklyMovementTarget,
                            weeklyWeighInTarget: weeklyWeighInTarget,
                            goalWeight: parsedGoal
                        )
                    )
                    dismiss()
                }
            }
        }
    }
}

struct CreateGoalSheet: View {
    let profile: UserProfile
    let goal: Goal?
    let onSave: (GoalFormValues) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: GoalType = .dietDays
    @State private var period: GoalPeriod = .week
    @State private var title: String = ""
    @State private var targetValue = "5"
    @State private var validationMessage = ""

    init(profile: UserProfile, goal: Goal? = nil, onSave: @escaping (GoalFormValues) -> Void) {
        self.profile = profile
        self.goal = goal
        self.onSave = onSave

        let initialType = goal?.type ?? .dietDays
        let initialPeriod = initialType == .weightTarget ? .custom : (goal?.period ?? .week)
        let initialTarget = goal.map { Self.targetText(for: $0.targetValue, type: $0.type) } ?? Self.defaultTarget(for: initialType, profile: profile)
        let initialTitle = goal?.title ?? Self.defaultTitle(for: initialType, targetText: initialTarget, period: initialPeriod, unit: profile.unit)

        _type = State(initialValue: initialType)
        _period = State(initialValue: initialPeriod)
        _targetValue = State(initialValue: initialTarget)
        _title = State(initialValue: initialTitle)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            SheetScaffold(title: goal == nil ? "Create goal" : "Edit goal", onClose: { dismiss() }) {
                AppCard(tint: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        SetupTextField(title: "Goal title", text: $title)

                        Text("Goal type")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppTheme.text)

                        Picker("Goal type", selection: $type) {
                            ForEach(GoalType.allCases) { goalType in
                                Text(goalType.label).tag(goalType)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: type) { _, newValue in
                            period = newValue == .weightTarget ? .custom : .week
                            targetValue = Self.defaultTarget(for: newValue, profile: profile)
                            title = Self.defaultTitle(for: newValue, targetText: targetValue, period: period, unit: profile.unit)
                        }

                        if type != .weightTarget {
                            Picker("Period", selection: $period) {
                                Text(GoalPeriod.week.label).tag(GoalPeriod.week)
                                Text(GoalPeriod.month.label).tag(GoalPeriod.month)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: period) { _, newValue in
                                title = Self.defaultTitle(for: type, targetText: targetValue, period: newValue, unit: profile.unit)
                            }
                        }

                        SetupNumberField(title: targetLabel, text: $targetValue, unit: targetUnit)
                    }
                }

                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } footer: {
                PrimaryButton(title: goal == nil ? "Create goal" : "Save goal", systemImage: goal == nil ? "plus.circle" : nil) {
                    submit()
                }
            }
        }
    }

    private func submit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Give this goal a short title."
            return
        }

        guard let target = Double(targetValue), target > 0 else {
            validationMessage = "Enter a target greater than zero."
            return
        }

        let savedPeriod = type == .weightTarget ? GoalPeriod.custom : period
        if type != .weightTarget {
            let maxTarget = savedPeriod == .month ? 31.0 : 7.0
            guard target.rounded() == target, target >= 1, target <= maxTarget else {
                validationMessage = savedPeriod == .month ? "Use a whole number from 1 to 31." : "Use a whole number from 1 to 7."
                return
            }
        }

        onSave(
            GoalFormValues(
                title: trimmedTitle,
                type: type,
                targetValue: target,
                period: savedPeriod
            )
        )
        dismiss()
    }

    private static func defaultTarget(for type: GoalType, profile: UserProfile) -> String {
        switch type {
        case .dietDays:
            "\(profile.weeklyDietTarget)"
        case .movementDays:
            "\(profile.weeklyMovementTarget)"
        case .weighIns:
            "\(profile.weeklyWeighInTarget)"
        case .weightTarget:
            String(format: "%.1f", profile.goalWeight)
        }
    }

    private static func targetText(for target: Double, type: GoalType) -> String {
        switch type {
        case .dietDays, .movementDays, .weighIns:
            "\(Int(target))"
        case .weightTarget:
            String(format: "%.1f", target)
        }
    }

    private static func defaultTitle(for type: GoalType, targetText: String, period: GoalPeriod, unit: String) -> String {
        let periodCopy = period == .month ? "this month" : "this week"
        switch type {
        case .dietDays:
            return "Follow diet \(targetText) days \(periodCopy)"
        case .movementDays:
            return "Move \(targetText) days \(periodCopy)"
        case .weighIns:
            return "Log weight \(targetText) times \(periodCopy)"
        case .weightTarget:
            return "Reach \(targetText) \(unit)"
        }
    }

    private var targetLabel: String {
        switch type {
        case .dietDays, .movementDays:
            period == .month ? "Days per month" : "Days per week"
        case .weighIns:
            period == .month ? "Times per month" : "Times per week"
        case .weightTarget:
            "Target weight"
        }
    }

    private var targetUnit: String {
        switch type {
        case .weightTarget:
            profile.unit
        default:
            ""
        }
    }
}

struct StreakMetric: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                Text("days")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(AppTheme.orange)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SelectablePill: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(AppTypography.primaryAction)
                Spacer()
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(selected ? AppTheme.primary : Color.clear))
                    .opacity(selected ? 1 : 0)
            }
            .foregroundStyle(AppTheme.text)
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(selected ? AppTheme.cardTint : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(selected ? AppTheme.primary : AppTheme.divider, lineWidth: selected ? 1.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.045), radius: 7, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SmallChoiceButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.primaryAction)
                .foregroundStyle(AppTheme.text)
                .frame(width: 62, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? AppTheme.cardTint : .white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected ? AppTheme.primary : AppTheme.divider, lineWidth: selected ? 1.2 : 1)
                        )
                        .shadow(color: .black.opacity(0.045), radius: 7, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

struct WeightTrendChart: View {
    let points: [TrendPoint]

    var body: some View {
        GeometryReader { proxy in
            let leftPadding: CGFloat = 40
            let bottomPadding: CGFloat = 60
            let topPadding: CGFloat = 12
            let width = max(proxy.size.width - leftPadding - 8, 1)
            let height = max(proxy.size.height - topPadding - bottomPadding, 1)
            let scale = WeightChartScale(weights: points.map(\.weight))

            ZStack(alignment: .topLeading) {
                ForEach(scale.labels, id: \.self) { label in
                    let y = topPadding + CGFloat(scale.normalizedY(for: label)) * height
                    Path { path in
                        path.move(to: CGPoint(x: leftPadding, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                    .stroke(AppTheme.divider.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    Text(scale.formatted(label))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .position(x: 18, y: y)
                }

                Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: topPadding))
                    path.addLine(to: CGPoint(x: leftPadding, y: topPadding + height))
                }
                .stroke(AppTheme.divider, lineWidth: 1)

                if points.count > 1 {
                    ChartAreaPath(points: points, leftPadding: leftPadding, topPadding: topPadding, width: width, height: height, minY: scale.minY, maxY: scale.maxY)
                        .fill(AppTheme.primary.opacity(0.10))

                    ChartLinePath(points: points, leftPadding: leftPadding, topPadding: topPadding, width: width, height: height, minY: scale.minY, maxY: scale.maxY)
                        .stroke(AppTheme.primary, lineWidth: 3)
                }

                ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                    let x = leftPadding + CGFloat(index) / CGFloat(max(points.count - 1, 1)) * width
                    let y = topPadding + CGFloat(scale.normalizedY(for: point.weight)) * height

                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .position(x: x, y: y)

                    Text(point.label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .position(
                            x: min(max(x, leftPadding + 10), proxy.size.width - 22),
                            y: proxy.size.height - (index.isMultiple(of: 2) ? 34 : 18)
                        )
                }

                Text("kg")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .position(x: 18, y: proxy.size.height - 18)
            }
        }
    }
}

private struct WeightChartScale {
    let minY: Double
    let maxY: Double
    let labels: [Double]

    init(weights: [Double]) {
        guard let minWeight = weights.min(), let maxWeight = weights.max() else {
            self.minY = 102
            self.maxY = 110
            self.labels = [110, 108, 106, 104, 102]
            return
        }

        let measuredRange = max(maxWeight - minWeight, 4)
        let padding = max(measuredRange * 0.16, 1)
        let step = Self.niceStep(for: (measuredRange + padding * 2) / 4)
        var lowerBound = floor(max(minWeight - padding, 0) / step) * step
        var upperBound = ceil((maxWeight + padding) / step) * step

        while ((upperBound - lowerBound) / step) < 4 {
            lowerBound = max(lowerBound - step, 0)
            upperBound += step
        }

        self.minY = lowerBound
        self.maxY = upperBound

        let intervalCount = max(Int(round((upperBound - lowerBound) / step)), 1)
        var generatedLabels = (0...intervalCount).map { upperBound - Double($0) * step }

        if generatedLabels.count > 7 {
            let labelStride = Int(ceil(Double(generatedLabels.count - 1) / 4))
            generatedLabels = generatedLabels.enumerated().compactMap { index, label in
                index.isMultiple(of: labelStride) ? label : nil
            }
            if let last = generatedLabels.last, abs(last - lowerBound) > 0.01 {
                generatedLabels.append(lowerBound)
            }
        }

        self.labels = generatedLabels
    }

    func normalizedY(for weight: Double) -> Double {
        guard maxY > minY else { return 0.5 }
        let ratio = (maxY - weight) / (maxY - minY)
        return min(max(ratio, 0), 1)
    }

    func formatted(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.01 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }

    private static func niceStep(for rawStep: Double) -> Double {
        guard rawStep.isFinite, rawStep > 0 else { return 1 }
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude

        let niceNormalized: Double
        switch normalized {
        case ...1:
            niceNormalized = 1
        case ...2:
            niceNormalized = 2
        case ...2.5:
            niceNormalized = 2.5
        case ...7.5:
            niceNormalized = 5
        default:
            niceNormalized = 10
        }

        return niceNormalized * magnitude
    }
}

struct ChartLinePath: Shape {
    let points: [TrendPoint]
    let leftPadding: CGFloat
    let topPadding: CGFloat
    let width: CGFloat
    let height: CGFloat
    let minY: Double
    let maxY: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (index, point) in points.enumerated() {
            let x = leftPadding + CGFloat(index) / CGFloat(max(points.count - 1, 1)) * width
            let y = yPosition(for: point.weight)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    private func yPosition(for weight: Double) -> CGFloat {
        guard maxY > minY else { return topPadding + height / 2 }
        let ratio = min(max((maxY - weight) / (maxY - minY), 0), 1)
        return topPadding + CGFloat(ratio) * height
    }
}

struct ChartAreaPath: Shape {
    let points: [TrendPoint]
    let leftPadding: CGFloat
    let topPadding: CGFloat
    let width: CGFloat
    let height: CGFloat
    let minY: Double
    let maxY: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        let baseline = topPadding + height
        let firstY = yPosition(for: first.weight)
        path.move(to: CGPoint(x: leftPadding, y: baseline))
        path.addLine(to: CGPoint(x: leftPadding, y: firstY))

        for (index, point) in points.enumerated() {
            let x = leftPadding + CGFloat(index) / CGFloat(max(points.count - 1, 1)) * width
            let y = yPosition(for: point.weight)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: leftPadding + width, y: baseline))
        path.closeSubpath()
        return path
    }

    private func yPosition(for weight: Double) -> CGFloat {
        guard maxY > minY else { return topPadding + height / 2 }
        let ratio = min(max((maxY - weight) / (maxY - minY), 0), 1)
        return topPadding + CGFloat(ratio) * height
    }
}

struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 15, height: 15)
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SummaryMetric: View {
    let symbol: String
    let value: String
    let label: String
    var tone: IconTone = .neutral
    var valueColor: Color = AppTheme.text

    var body: some View {
        VStack(spacing: 8) {
            IconBubble(symbol: symbol, tone: tone)
                .frame(width: 52, height: 52)
            Text(value)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity)
    }
}

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \DailyCheckIn.date) private var checkIns: [DailyCheckIn]
    @Query(sort: \WeightEntry.date) private var weightEntries: [WeightEntry]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    var body: some View {
        Group {
            if let profile = profiles.first {
                MainAppShell(profile: profile, checkIns: checkIns, weightEntries: weightEntries, goals: goals)
            } else {
                OnboardingScreen { setup in
                    createProfile(setup)
                }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.light)
    }

    private func createProfile(_ setup: SetupValues) {
        let profile = UserProfile(
            startingWeight: setup.startingWeight,
            currentWeight: setup.currentWeight,
            goalWeight: setup.goalWeight,
            unit: setup.unit,
            weeklyDietTarget: setup.weeklyDietTarget,
            weeklyMovementTarget: setup.weeklyMovementTarget,
            weeklyWeighInTarget: setup.weeklyWeighInTarget,
            displayName: setup.displayName
        )
        modelContext.insert(profile)
        modelContext.insert(WeightEntry(date: Date(), weight: setup.currentWeight))
        Goal.defaults(for: profile).forEach(modelContext.insert)
        try? modelContext.save()
    }
}

private enum GoalSheetDestination: Identifiable {
    case adjustTargets
    case create
    case edit(Goal)

    var id: String {
        switch self {
        case .adjustTargets:
            "adjust-targets"
        case .create:
            "create-goal"
        case .edit(let goal):
            "edit-\(goal.id.uuidString)"
        }
    }
}

struct MainAppShell: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile
    let checkIns: [DailyCheckIn]
    let weightEntries: [WeightEntry]
    let goals: [Goal]

    @State private var selectedTab: AppTab = .today
    @State private var isCheckingIn = false
    @State private var displayedMonth = Date()
    @State private var goalSheet: GoalSheetDestination?
    @State private var isShowingProfile = false
    @State private var isAddingPastWeight = false

    private var metrics: TrackerMetrics {
        TrackerMetrics(profile: profile, checkIns: checkIns, weightEntries: weightEntries, goals: goals, displayedMonth: displayedMonth)
    }

    var body: some View {
        ZStack {
            if isCheckingIn {
                AppTheme.background
                    .ignoresSafeArea()
                CheckInScreen(
                    profile: profile,
                    existingCheckIn: metrics.todayCheckIn,
                    onCancel: { isCheckingIn = false },
                    onSave: saveCheckIn
                )
            } else {
                TabView(selection: $selectedTab) {
                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            TodayScreen(
                                metrics: metrics,
                                onProfileTap: { isShowingProfile = true },
                                onStartCheckIn: { isCheckingIn = true }
                            )
                        }
                        .tag(AppTab.today)
                        .tabItem {
                            Label(AppTab.today.title, systemImage: AppTab.today.icon)
                        }

                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            ProgressScreen(
                                metrics: metrics,
                                onProfileTap: { isShowingProfile = true },
                                onAddPastWeight: { isAddingPastWeight = true }
                            )
                        }
                        .tag(AppTab.progress)
                        .tabItem {
                            Label(AppTab.progress.title, systemImage: AppTab.progress.icon)
                        }

                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            GoalsScreen(
                                metrics: metrics,
                                onProfileTap: { isShowingProfile = true },
                                onAdjustTargets: { goalSheet = .adjustTargets },
                                onCreateGoal: { goalSheet = .create },
                                onEditGoal: { goalSheet = .edit($0) },
                                onDeleteGoal: deleteExtraGoal
                            )
                        }
                        .tag(AppTab.goals)
                        .tabItem {
                            Label(AppTab.goals.title, systemImage: AppTab.goals.icon)
                        }

                    AppTheme.background
                        .ignoresSafeArea()
                        .overlay {
                            HistoryScreen(
                                metrics: metrics,
                                onProfileTap: { isShowingProfile = true },
                                onPreviousMonth: { displayedMonth = shiftedMonth(by: -1) },
                                onNextMonth: { displayedMonth = shiftedMonth(by: 1) }
                            )
                        }
                        .tag(AppTab.history)
                        .tabItem {
                            Label(AppTab.history.title, systemImage: AppTab.history.icon)
                        }
                }
                .toolbarBackground(.automatic, for: .tabBar)
                .toolbarColorScheme(.light, for: .tabBar)
            }
        }
        .fullScreenCover(isPresented: $isShowingProfile) {
            ProfileSettingsScreen(
                metrics: metrics,
                onClose: { isShowingProfile = false },
                onSaveIdentity: saveIdentity,
                onSaveProfileImage: saveProfileImage,
                onRemoveProfileImage: removeProfileImage,
                onSaveBaseline: saveBaseline,
                onSaveTargets: saveTargets,
                onSaveUnit: saveUnit,
                onResetData: resetLocalData
            )
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab != .today {
                isCheckingIn = false
            }
        }
        .sheet(item: $goalSheet) { destination in
            switch destination {
            case .adjustTargets:
                AdjustTargetsSheet(profile: profile) { values in
                    saveTargets(values)
                    goalSheet = nil
                }
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
            case .create:
                CreateGoalSheet(profile: profile) { values in
                    modelContext.insert(
                        Goal(
                            type: values.type,
                            title: values.title,
                            targetValue: values.targetValue,
                            period: values.period
                        )
                    )
                    refreshGoals()
                    try? modelContext.save()
                    goalSheet = nil
                }
                .presentationDetents([.height(620)])
                .presentationDragIndicator(.visible)
            case .edit(let goal):
                CreateGoalSheet(profile: profile, goal: goal) { values in
                    goal.type = values.type
                    goal.title = values.title
                    goal.targetValue = values.targetValue
                    goal.period = values.period
                    goal.core = false
                    goal.updatedStatus(using: metrics)
                    refreshGoals()
                    try? modelContext.save()
                    goalSheet = nil
                }
                .presentationDetents([.height(620)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isAddingPastWeight) {
            AddWeightEntrySheet(profile: profile, onSave: saveWeightEntry)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .task {
            backfillWeightEntries()
            ensureCoreGoals()
            refreshGoals()
        }
    }

    private func saveCheckIn(dietStatus: DietStatus, moved: Bool, weight: Double?) {
        let today = Calendar.current.startOfDay(for: Date())
        let hadWeight = metrics.todayCheckIn?.weight != nil

        if let existing = metrics.todayCheckIn {
            existing.dietStatus = dietStatus
            existing.moved = moved
            existing.weight = weight
            existing.updatedAt = Date()
        } else {
            modelContext.insert(
                DailyCheckIn(
                    date: today,
                    dietStatus: dietStatus,
                    moved: moved,
                    weight: weight
                )
            )
        }

        if let weight {
            upsertWeightEntry(on: today, weight: weight)
        } else if let existingEntry = weightEntry(on: today), hadWeight {
            modelContext.delete(existingEntry)
            profile.currentWeight = latestWeightExcluding(date: today) ?? profile.currentWeight
            profile.updatedAt = Date()
        }

        ensureCoreGoals()
        refreshGoals()
        try? modelContext.save()
        isCheckingIn = false
    }

    private func ensureCoreGoals() {
        for type in GoalType.allCases {
            let coreGoals = goals
                .filter { $0.core && $0.type == type }
                .sorted { $0.createdAt < $1.createdAt }

            if let primary = coreGoals.first {
                updateCoreGoal(primary, type: type)
                coreGoals.dropFirst().forEach { $0.core = false }
            } else if let existing = goals
                .filter({ !$0.core && $0.type == type })
                .sorted(by: { $0.createdAt < $1.createdAt })
                .first {
                updateCoreGoal(existing, type: type)
            } else {
                modelContext.insert(Goal.coreGoal(for: type, profile: profile))
            }
        }
        try? modelContext.save()
    }

    private func refreshGoals() {
        for type in GoalType.allCases {
            goals
                .filter { $0.core && $0.type == type }
                .forEach { updateCoreGoal($0, type: type) }
        }

        let freshMetrics = TrackerMetrics(profile: profile, checkIns: checkIns, weightEntries: weightEntries, goals: goals, displayedMonth: displayedMonth)
        for goal in goals {
            goal.currentValue = freshMetrics.currentValue(for: goal)
            let status = freshMetrics.displayStatus(for: goal)
            if goal.status != status {
                goal.status = status
                goal.completedAt = status == .completed ? Date() : nil
            }
        }
    }

    private func updateCoreGoal(_ goal: Goal, type: GoalType) {
        goal.core = true
        goal.type = type
        goal.title = Goal.coreTitle(for: type, profile: profile)
        goal.targetValue = Goal.coreTargetValue(for: type, profile: profile)
        goal.period = Goal.corePeriod(for: type)
    }

    private func saveTargets(_ values: GoalTargetValues) {
        profile.weeklyDietTarget = values.weeklyDietTarget
        profile.weeklyMovementTarget = values.weeklyMovementTarget
        profile.weeklyWeighInTarget = values.weeklyWeighInTarget
        profile.goalWeight = values.goalWeight
        profile.updatedAt = Date()
        ensureCoreGoals()
        refreshGoals()
        try? modelContext.save()
    }

    private func saveIdentity(_ values: ProfileIdentityValues) {
        profile.displayName = values.displayName
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func saveProfileImage(_ imageData: Data) {
        profile.profileImageData = imageData
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func removeProfileImage() {
        profile.profileImageData = nil
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func saveBaseline(_ values: ProfileBaselineValues) {
        profile.startingWeight = values.startingWeight
        profile.currentWeight = values.currentWeight
        profile.goalWeight = values.goalWeight
        profile.updatedAt = Date()

        if let latestWeightEntry {
            latestWeightEntry.weight = values.currentWeight
            latestWeightEntry.updatedAt = Date()
        }

        ensureCoreGoals()
        refreshGoals()
        try? modelContext.save()
    }

    private func saveUnit(_ newUnit: String) {
        let oldUnit = profile.unit
        guard oldUnit != newUnit else { return }

        profile.startingWeight = WeightUnitConverter.converted(profile.startingWeight, from: oldUnit, to: newUnit)
        profile.currentWeight = WeightUnitConverter.converted(profile.currentWeight, from: oldUnit, to: newUnit)
        profile.goalWeight = WeightUnitConverter.converted(profile.goalWeight, from: oldUnit, to: newUnit)
        profile.unit = newUnit
        profile.updatedAt = Date()

        for checkIn in checkIns {
            if let weight = checkIn.weight {
                checkIn.weight = WeightUnitConverter.converted(weight, from: oldUnit, to: newUnit)
                checkIn.updatedAt = Date()
            }
        }

        for entry in weightEntries {
            entry.weight = WeightUnitConverter.converted(entry.weight, from: oldUnit, to: newUnit)
            entry.updatedAt = Date()
        }

        for goal in goals where goal.type == .weightTarget {
            goal.targetValue = WeightUnitConverter.converted(goal.targetValue, from: oldUnit, to: newUnit)
            if !goal.core {
                goal.title = goal.title.replacingOccurrences(of: " \(oldUnit)", with: " \(newUnit)")
            }
        }

        ensureCoreGoals()
        refreshGoals()
        try? modelContext.save()
    }

    private func resetLocalData() {
        isShowingProfile = false
        checkIns.forEach(modelContext.delete)
        weightEntries.forEach(modelContext.delete)
        goals.forEach(modelContext.delete)
        modelContext.delete(profile)
        try? modelContext.save()
    }

    private func deleteExtraGoal(_ goal: Goal) {
        guard !goal.core else { return }
        modelContext.delete(goal)
        try? modelContext.save()
    }

    private func shiftedMonth(by value: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func saveWeightEntry(date: Date, weight: Double) {
        upsertWeightEntry(on: date, weight: weight)
        ensureCoreGoals()
        refreshGoals()
        try? modelContext.save()
    }

    private func upsertWeightEntry(on date: Date, weight: Double) {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = weightEntry(on: day) {
            existing.weight = weight
            existing.updatedAt = Date()
        } else {
            modelContext.insert(WeightEntry(date: day, weight: weight))
        }

        if isLatestWeightDate(day) {
            profile.currentWeight = weight
            profile.updatedAt = Date()
        }
    }

    private func backfillWeightEntries() {
        var didInsert = false
        for checkIn in checkIns {
            guard let weight = checkIn.weight, weightEntry(on: checkIn.date) == nil else { continue }
            modelContext.insert(
                WeightEntry(
                    date: checkIn.date,
                    weight: weight,
                    createdAt: checkIn.createdAt,
                    updatedAt: checkIn.updatedAt
                )
            )
            didInsert = true
        }

        if !didInsert, weightEntries.isEmpty {
            modelContext.insert(WeightEntry(date: profile.createdAt, weight: profile.currentWeight, createdAt: profile.createdAt, updatedAt: profile.updatedAt))
            didInsert = true
        }

        if didInsert {
            try? modelContext.save()
        }
    }

    private func weightEntry(on date: Date) -> WeightEntry? {
        let day = Calendar.current.startOfDay(for: date)
        return weightEntries.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private var latestWeightEntry: WeightEntry? {
        let calendar = Calendar.current
        return weightEntries
            .sorted {
                if calendar.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.updatedAt < $1.updatedAt
                }
                return $0.date < $1.date
            }
            .last
    }

    private func isLatestWeightDate(_ savedDate: Date) -> Bool {
        let calendar = Calendar.current
        let savedDay = calendar.startOfDay(for: savedDate)
        guard let existingLatest = weightEntries.map(\.date).max() else { return true }
        return savedDay >= calendar.startOfDay(for: existingLatest)
    }

    private func latestWeightExcluding(date: Date) -> Double? {
        let calendar = Calendar.current
        let excludedDay = calendar.startOfDay(for: date)
        return weightEntries
            .filter { !calendar.isDate($0.date, inSameDayAs: excludedDay) }
            .sorted { $0.date < $1.date }
            .last?
            .weight
    }
}

private extension Goal {
    func updatedStatus(using metrics: TrackerMetrics) {
        currentValue = metrics.currentValue(for: self)
        status = metrics.displayStatus(for: self)
        completedAt = status == .completed ? Date() : nil
    }
}

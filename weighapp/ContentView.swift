import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \DailyCheckIn.date) private var checkIns: [DailyCheckIn]
    @Query(sort: \WeightEntry.date) private var weightEntries: [WeightEntry]
    @Query(sort: \BodyMeasurementEntry.date) private var measurementEntries: [BodyMeasurementEntry]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Query(sort: \Challenge.createdAt) private var challenges: [Challenge]
    @Query(sort: \NutritionistConnection.pairedAt) private var nutritionistConnections: [NutritionistConnection]
    @Query(sort: \MealPlanCache.updatedAt) private var mealPlanCaches: [MealPlanCache]
    @Query(sort: \EarnedAchievement.earnedAt) private var earnedAchievements: [EarnedAchievement]

    @State private var isShowingLaunchSplash = true
    @State private var launchSplashOpacity = 1.0
    @State private var didStartLaunchSplashDismissal = false

    var body: some View {
        appContent
            .tint(AppTheme.primary)
            .preferredColorScheme(.light)
            .overlay {
                if isShowingLaunchSplash {
                    SplashScreenView()
                        .opacity(launchSplashOpacity)
                        .transition(.opacity)
                        .zIndex(1)
                        .accessibilityHidden(true)
                }
            }
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                guard newPhase == .active else { return }
                startLaunchSplashDismissal()
            }
    }

    private var appContent: some View {
        Group {
            if let profile = profiles.first {
                MainAppShell(
                    profile: profile,
                    checkIns: checkIns,
                    weightEntries: weightEntries,
                    measurementEntries: measurementEntries,
                    goals: goals,
                    challenges: challenges,
                    nutritionistConnections: nutritionistConnections,
                    mealPlanCaches: mealPlanCaches,
                    earnedAchievements: earnedAchievements
                )
            } else {
                OnboardingScreen { setup in
                    createProfile(setup)
                }
            }
        }
    }

    private func startLaunchSplashDismissal() {
        guard !didStartLaunchSplashDismissal else { return }
        didStartLaunchSplashDismissal = true

        Task { @MainActor in
            await dismissLaunchSplash()
        }
    }

    @MainActor
    private func dismissLaunchSplash() async {
        guard isShowingLaunchSplash else { return }

        let displayDuration: UInt64 = reduceMotion ? 500_000_000 : 1_600_000_000
        try? await Task.sleep(nanoseconds: displayDuration)

        if reduceMotion {
            isShowingLaunchSplash = false
            return
        }

        withAnimation(.easeOut(duration: 0.35)) {
            launchSplashOpacity = 0
        }

        try? await Task.sleep(nanoseconds: 350_000_000)
        isShowingLaunchSplash = false
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
            displayName: setup.displayName,
            checkInReminderEnabled: setup.checkInReminderEnabled,
            checkInReminderHour: setup.checkInReminderHour,
            checkInReminderMinute: setup.checkInReminderMinute,
            flexDaysEnabled: setup.flexDaysEnabled,
            flexWeekdayMask: setup.flexWeekdayMask,
            chestMeasurement: setup.chestMeasurement,
            waistMeasurement: setup.waistMeasurement,
            hipsMeasurement: setup.hipsMeasurement,
            bodyMeasurementUnit: setup.bodyMeasurementUnit
        )
        modelContext.insert(profile)
        modelContext.insert(WeightEntry(date: Date(), weight: setup.currentWeight))
        let measurementSnapshot = BodyMeasurementSnapshot(
            chest: setup.chestMeasurement,
            waist: setup.waistMeasurement,
            hips: setup.hipsMeasurement,
            unit: setup.bodyMeasurementUnit
        )
        if measurementSnapshot.hasAnyValue {
            modelContext.insert(
                BodyMeasurementEntry(
                    date: Date(),
                    chest: measurementSnapshot.chest,
                    waist: measurementSnapshot.waist,
                    hips: measurementSnapshot.hips,
                    unit: measurementSnapshot.unit
                )
            )
        }
        Goal.defaults(for: profile).forEach(modelContext.insert)
        try? modelContext.save()
        Task { @MainActor in
            await CheckInReminderScheduler.refresh(profile: profile, checkIns: [])
        }
    }
}

private struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.941, green: 0.988, blue: 0.946)
                    .ignoresSafeArea()

                Image("LeafstepSplash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .ignoresSafeArea()

                SplashLoadingRing(reduceMotion: reduceMotion, rotation: rotation)
                    .frame(width: 70, height: 70)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.844)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

private struct SplashLoadingRing: View {
    let reduceMotion: Bool
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.primary.opacity(0.14), lineWidth: 6)

            Circle()
                .trim(from: 0, to: 0.82)
                .stroke(
                    AppTheme.primary,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(reduceMotion ? -90 : rotation - 90))

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(y: -35)
                .rotationEffect(.degrees(reduceMotion ? 0 : rotation))
        }
        .shadow(color: AppTheme.primary.opacity(0.16), radius: 8, y: 3)
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

private enum ChallengeSheetDestination: Identifiable {
    case create
    case edit(Challenge)

    var id: String {
        switch self {
        case .create:
            "create-challenge"
        case .edit(let challenge):
            "edit-challenge-\(challenge.id.uuidString)"
        }
    }
}

struct MainAppShell: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var notificationRouter: CheckInNotificationRouter
    let profile: UserProfile
    let checkIns: [DailyCheckIn]
    let weightEntries: [WeightEntry]
    let measurementEntries: [BodyMeasurementEntry]
    let goals: [Goal]
    let challenges: [Challenge]
    let nutritionistConnections: [NutritionistConnection]
    let mealPlanCaches: [MealPlanCache]
    let earnedAchievements: [EarnedAchievement]

    @State private var selectedTab: AppTab = .today
    @State private var isCheckingIn = false
    @State private var displayedMonth = Date()
    @State private var goalSheet: GoalSheetDestination?
    @State private var challengeSheet: ChallengeSheetDestination?
    @State private var isShowingProfile = false
    @State private var isAddingPastWeight = false
    @State private var isAddingMeasurements = false
    @State private var isShowingAchievements = false
    @State private var isShowingAchievementUnlock = false
    @State private var pendingAchievementUnlocks: [AchievementDefinition] = []

    private var metrics: TrackerMetrics {
        TrackerMetrics(
            profile: profile,
            checkIns: checkIns,
            weightEntries: weightEntries,
            measurementEntries: measurementEntries,
            goals: goals,
            challenges: challenges,
            earnedAchievements: earnedAchievements,
            displayedMonth: displayedMonth
        )
    }

    private var mealPlanConnection: NutritionistConnection? {
        nutritionistConnections.sorted { $0.pairedAt > $1.pairedAt }.first
    }

    private var mealPlanCache: MealPlanCache? {
        guard let mealPlanConnection else { return nil }
        return mealPlanCaches
            .filter { $0.connectionID == mealPlanConnection.connectionID && $0.planID == mealPlanConnection.planID }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    private var shouldShowMealPlanTab: Bool {
        mealPlanConnection != nil
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
                                    onStartCheckIn: { isCheckingIn = true },
                                    onLogWeight: { isAddingPastWeight = true }
                                )
                            }
                            .tag(AppTab.today)
                            .tabItem {
                                Label(AppTab.today.title, systemImage: AppTab.today.icon)
                            }

                        if shouldShowMealPlanTab {
                            AppTheme.background
                                .ignoresSafeArea()
                                .overlay {
                                    MealPlanScreen(
                                        connection: mealPlanConnection,
                                        cache: mealPlanCache,
                                        profileImageData: profile.profileImageData,
                                        onProfileTap: { isShowingProfile = true },
                                        onRefresh: refreshMealPlan,
                                        onDisconnect: disconnectMealPlan
                                    )
                                }
                                .tag(AppTab.mealPlan)
                                .tabItem {
                                    Label(AppTab.mealPlan.title, systemImage: AppTab.mealPlan.icon)
                                }
                        }

                        AppTheme.background
                            .ignoresSafeArea()
                            .overlay {
                                ProgressScreen(
                                    metrics: metrics,
                                    onProfileTap: { isShowingProfile = true },
                                    onLogWeight: { isAddingPastWeight = true },
                                    onAddMeasurements: { isAddingMeasurements = true },
                                    onShowAchievements: { isShowingAchievements = true }
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
                                    onDeleteGoal: deleteExtraGoal,
                                    onCreateChallenge: { challengeSheet = .create },
                                    onEditChallenge: { challengeSheet = .edit($0) },
                                    onDeleteChallenge: deleteChallenge,
                                    onToggleChallengePin: toggleChallengePin
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
                mealPlanConnection: mealPlanConnection,
                mealPlanCache: mealPlanCache,
                onClose: { isShowingProfile = false },
                onSaveIdentity: saveIdentity,
                onSaveProfileImage: saveProfileImage,
                onRemoveProfileImage: removeProfileImage,
                onSaveBaseline: saveBaseline,
                onSaveTargets: saveTargets,
                onSaveUnit: saveUnit,
                onSaveReminder: saveReminder,
                onSaveFlexDays: saveFlexDays,
                onPairMealPlan: pairMealPlan,
                onRefreshMealPlan: refreshMealPlan,
                onDisconnectMealPlan: disconnectMealPlan,
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
        .sheet(item: $challengeSheet) { destination in
            switch destination {
            case .create:
                CreateChallengeSheet(
                    profile: profile,
                    latestWeight: metrics.latestWeight,
                    activeChallengeCount: metrics.activeChallengeCount,
                    challenge: nil,
                    onSave: saveChallenge
                )
                .presentationDetents([.height(660)])
                .presentationDragIndicator(.visible)
            case .edit(let challenge):
                CreateChallengeSheet(
                    profile: profile,
                    latestWeight: metrics.latestWeight,
                    activeChallengeCount: metrics.activeChallengeCount,
                    challenge: challenge,
                    onSave: { values in
                        saveChallenge(values, existing: challenge)
                    }
                )
                .presentationDetents([.height(660)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isAddingPastWeight) {
            AddWeightEntrySheet(profile: profile, onSave: saveWeightEntry)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddingMeasurements) {
            AddBodyMeasurementsSheet(
                profile: profile,
                latestMeasurement: metrics.latestMeasurementSnapshot,
                onSave: saveBodyMeasurementEntry
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAchievements) {
            AchievementsSheet(metrics: metrics)
                .presentationDetents([.height(620)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAchievementUnlock, onDismiss: {
            pendingAchievementUnlocks = []
        }) {
            AchievementUnlockSheet(
                achievements: pendingAchievementUnlocks,
                onNice: {
                    isShowingAchievementUnlock = false
                    pendingAchievementUnlocks = []
                },
                onViewAll: {
                    isShowingAchievementUnlock = false
                    let delay = UInt64(250_000_000)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: delay)
                        pendingAchievementUnlocks = []
                        isShowingAchievements = true
                    }
                }
            )
            .presentationDetents([.height(achievementUnlockSheetHeight)])
            .presentationDragIndicator(.visible)
        }
        .task {
            backfillWeightEntries()
            backfillBodyMeasurementEntries()
            ensureCoreGoals()
            refreshGoals()
            refreshChallenges()
            evaluateAchievements()
            await CheckInReminderScheduler.refresh(profile: profile, checkIns: checkIns)
            if notificationRouter.pendingCheckInReminderRouteID != nil {
                routeToCheckInReminder()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { @MainActor in
                await CheckInReminderScheduler.refresh(profile: profile, checkIns: checkIns)
            }
        }
        .onChange(of: notificationRouter.pendingCheckInReminderRouteID) { _, routeID in
            guard routeID != nil else { return }
            routeToCheckInReminder()
        }
    }

    private var achievementUnlockSheetHeight: CGFloat {
        pendingAchievementUnlocks.count > 1 ? min(CGFloat(280 + pendingAchievementUnlocks.count * 74), 620) : 360
    }

    private func saveCheckIn(dietStatus: DietStatus, moved: Bool, weight: Double?, measurement: BodyMeasurementSnapshot?) {
        let today = Calendar.current.startOfDay(for: Date())
        let hadWeight = metrics.todayCheckIn?.weight != nil
        let savedCheckIn: DailyCheckIn

        if let existing = metrics.todayCheckIn {
            existing.dietStatus = dietStatus
            existing.moved = moved
            existing.weight = weight
            existing.updatedAt = Date()
            savedCheckIn = existing
        } else {
            let newCheckIn = DailyCheckIn(
                date: today,
                dietStatus: dietStatus,
                moved: moved,
                weight: weight
            )
            modelContext.insert(newCheckIn)
            savedCheckIn = newCheckIn
        }

        if let weight {
            upsertWeightEntry(on: today, weight: weight)
        } else if let existingEntry = weightEntry(on: today), hadWeight {
            modelContext.delete(existingEntry)
            profile.currentWeight = latestWeightExcluding(date: today) ?? profile.currentWeight
            profile.updatedAt = Date()
        }

        if let measurement, measurement.hasAnyValue {
            upsertBodyMeasurementEntry(on: today, snapshot: measurement)
        }

        ensureCoreGoals()
        refreshGoals()
        refreshChallenges()
        try? modelContext.save()
        let alreadyInQuery = checkIns.contains { Calendar.current.isDate($0.date, inSameDayAs: savedCheckIn.date) }
        let schedulerCheckIns = alreadyInQuery ? checkIns : checkIns + [savedCheckIn]
        Task { @MainActor in
            await CheckInReminderScheduler.refresh(profile: profile, checkIns: schedulerCheckIns)
        }
        isCheckingIn = false
        evaluateAchievements(presentsUnlocks: true)
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

        let freshMetrics = TrackerMetrics(
            profile: profile,
            checkIns: checkIns,
            weightEntries: weightEntries,
            measurementEntries: measurementEntries,
            goals: goals,
            challenges: challenges,
            earnedAchievements: earnedAchievements,
            displayedMonth: displayedMonth
        )
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

    @discardableResult
    private func evaluateAchievements(presentsUnlocks: Bool = false) -> [AchievementDefinition] {
        let fetchedCheckIns = (try? modelContext.fetch(FetchDescriptor<DailyCheckIn>())) ?? checkIns
        let fetchedWeights = (try? modelContext.fetch(FetchDescriptor<WeightEntry>())) ?? weightEntries
        let fetchedMeasurements = (try? modelContext.fetch(FetchDescriptor<BodyMeasurementEntry>())) ?? measurementEntries
        let fetchedAchievements = (try? modelContext.fetch(FetchDescriptor<EarnedAchievement>())) ?? earnedAchievements
        let evaluationMetrics = TrackerMetrics(
            profile: profile,
            checkIns: fetchedCheckIns,
            weightEntries: fetchedWeights,
            measurementEntries: fetchedMeasurements,
            goals: goals,
            challenges: challenges,
            earnedAchievements: fetchedAchievements,
            displayedMonth: displayedMonth
        )
        let unlockedKeys = AchievementEvaluator.unlockedKeys(using: evaluationMetrics)
        var existingKeys = Set(fetchedAchievements.map(\.key).filter(AchievementCatalog.contains))
        let now = Date()
        var didChange = false
        var newlyEarned: [AchievementDefinition] = []

        for achievement in fetchedAchievements where !AchievementCatalog.contains(achievement.key) {
            modelContext.delete(achievement)
            didChange = true
        }

        for definition in AchievementCatalog.definitions where unlockedKeys.contains(definition.key) && !existingKeys.contains(definition.key) {
            modelContext.insert(EarnedAchievement(key: definition.key, earnedAt: now, createdAt: now))
            existingKeys.insert(definition.key)
            newlyEarned.append(definition)
            didChange = true
        }

        if didChange {
            try? modelContext.save()
        }

        if presentsUnlocks {
            presentAchievementUnlocks(newlyEarned)
        }

        return newlyEarned
    }

    private func presentAchievementUnlocks(_ definitions: [AchievementDefinition]) {
        guard !definitions.isEmpty else { return }
        let pendingKeys = Set(pendingAchievementUnlocks.map(\.key))
        pendingAchievementUnlocks += definitions.filter { !pendingKeys.contains($0.key) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard !pendingAchievementUnlocks.isEmpty else { return }
            isShowingAchievementUnlock = true
        }
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
        refreshChallenges()
        try? modelContext.save()
    }

    private func saveUnit(_ values: UnitPreferenceValues) {
        let oldWeightUnit = profile.unit
        let newWeightUnit = values.weightUnit
        let oldMeasurementUnit = profile.bodyMeasurementUnit
        let newMeasurementUnit = values.bodyMeasurementUnit
        let weightUnitChanged = oldWeightUnit != newWeightUnit
        let measurementUnitChanged = oldMeasurementUnit != newMeasurementUnit

        guard weightUnitChanged || measurementUnitChanged || profile.bodyMeasurementUnitValue != newMeasurementUnit else { return }

        let now = Date()

        if weightUnitChanged {
            profile.startingWeight = WeightUnitConverter.converted(profile.startingWeight, from: oldWeightUnit, to: newWeightUnit)
            profile.currentWeight = WeightUnitConverter.converted(profile.currentWeight, from: oldWeightUnit, to: newWeightUnit)
            profile.goalWeight = WeightUnitConverter.converted(profile.goalWeight, from: oldWeightUnit, to: newWeightUnit)
            profile.unit = newWeightUnit

            for checkIn in checkIns {
                if let weight = checkIn.weight {
                    checkIn.weight = WeightUnitConverter.converted(weight, from: oldWeightUnit, to: newWeightUnit)
                    checkIn.updatedAt = now
                }
            }

            for entry in weightEntries {
                entry.weight = WeightUnitConverter.converted(entry.weight, from: oldWeightUnit, to: newWeightUnit)
                entry.updatedAt = now
            }

            for goal in goals where goal.type == .weightTarget {
                goal.targetValue = WeightUnitConverter.converted(goal.targetValue, from: oldWeightUnit, to: newWeightUnit)
                if !goal.core {
                    goal.title = goal.title.replacingOccurrences(of: " \(oldWeightUnit)", with: " \(newWeightUnit)")
                }
            }

            for challenge in challenges where challenge.kind == .weightLoss {
                challenge.targetValue = WeightUnitConverter.converted(challenge.targetValue, from: oldWeightUnit, to: newWeightUnit)
                if let baselineWeight = challenge.baselineWeight {
                    challenge.baselineWeight = WeightUnitConverter.converted(baselineWeight, from: oldWeightUnit, to: newWeightUnit)
                }
                challenge.unit = newWeightUnit
                challenge.updatedAt = now
                challenge.title = challenge.title.replacingOccurrences(of: " \(oldWeightUnit)", with: " \(newWeightUnit)")
            }
        }

        if measurementUnitChanged {
            profile.chestMeasurement = convertedBodyMeasurement(profile.chestMeasurement, from: oldMeasurementUnit, to: newMeasurementUnit)
            profile.waistMeasurement = convertedBodyMeasurement(profile.waistMeasurement, from: oldMeasurementUnit, to: newMeasurementUnit)
            profile.hipsMeasurement = convertedBodyMeasurement(profile.hipsMeasurement, from: oldMeasurementUnit, to: newMeasurementUnit)

            for entry in measurementEntries {
                entry.chest = convertedBodyMeasurement(entry.chest, from: oldMeasurementUnit, to: newMeasurementUnit)
                entry.waist = convertedBodyMeasurement(entry.waist, from: oldMeasurementUnit, to: newMeasurementUnit)
                entry.hips = convertedBodyMeasurement(entry.hips, from: oldMeasurementUnit, to: newMeasurementUnit)
                entry.unit = newMeasurementUnit
                entry.updatedAt = now
            }
        }

        profile.bodyMeasurementUnit = newMeasurementUnit
        profile.updatedAt = now

        if weightUnitChanged {
            ensureCoreGoals()
            refreshGoals()
            refreshChallenges()
        }

        try? modelContext.save()
    }

    private func convertedBodyMeasurement(_ value: Double?, from oldUnit: String, to newUnit: String) -> Double? {
        guard let value else { return nil }
        return BodyMeasurementUnitConverter.converted(value, from: oldUnit, to: newUnit)
    }

    private func saveReminder(_ values: CheckInReminderValues) {
        profile.checkInReminderEnabled = values.enabled
        profile.checkInReminderHour = values.hour
        profile.checkInReminderMinute = values.minute
        profile.updatedAt = Date()
        try? modelContext.save()

        Task { @MainActor in
            await CheckInReminderScheduler.refresh(profile: profile, checkIns: checkIns)
        }
    }

    private func saveFlexDays(_ values: FlexDaysPreferenceValues) {
        profile.flexDaysEnabled = values.enabled
        profile.flexWeekdayMask = values.enabled ? values.weekdayMask : 0
        profile.updatedAt = Date()
        refreshGoals()
        try? modelContext.save()
    }

    private func pairMealPlan(payload: String) -> String? {
        let trimmedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPayload.isEmpty else {
            return "Scan or enter the pairing code from your nutritionist."
        }

        let lowercasePayload = trimmedPayload.lowercased()
        guard !lowercasePayload.contains("expired") else {
            return "That pairing code has expired. Ask your nutritionist for a fresh code."
        }
        guard !lowercasePayload.contains("revoked") && !lowercasePayload.contains("used") else {
            return "That pairing code is no longer available. Ask your nutritionist for a new one."
        }

        nutritionistConnections.forEach(modelContext.delete)
        mealPlanCaches.forEach(modelContext.delete)

        let now = Date()
        let connection = NutritionistConnection(
            connectionID: "conn-\(UUID().uuidString)",
            nutritionistDisplayName: "Dr. Rivera, RD",
            planID: "steady-week-plan",
            status: .active,
            accessToken: "local-demo-\(UUID().uuidString)",
            pairedAt: now,
            lastSyncAt: now,
            updatedAt: now
        )
        modelContext.insert(connection)
        modelContext.insert(demoMealPlanCache(for: connection, updatedAt: now))
        try? modelContext.save()
        selectedTab = .mealPlan
        return nil
    }

    private func refreshMealPlan() {
        guard let connection = mealPlanConnection else { return }
        guard connection.status == .active else {
            connection.updatedAt = Date()
            try? modelContext.save()
            return
        }

        let now = Date()
        connection.lastSyncAt = now
        connection.updatedAt = now

        if let cache = mealPlanCache {
            cache.revision += 1
            cache.title = MealPlanDemoFactory.plan().title
            cache.planJSON = MealPlanDemoFactory.encodedPlan()
            cache.updatedAt = now
        } else {
            modelContext.insert(demoMealPlanCache(for: connection, updatedAt: now))
        }

        try? modelContext.save()
    }

    private func disconnectMealPlan() {
        nutritionistConnections.forEach(modelContext.delete)
        mealPlanCaches.forEach(modelContext.delete)
        if selectedTab == .mealPlan {
            selectedTab = .today
        }
        try? modelContext.save()
    }

    private func demoMealPlanCache(for connection: NutritionistConnection, updatedAt: Date) -> MealPlanCache {
        let plan = MealPlanDemoFactory.plan()
        return MealPlanCache(
            connectionID: connection.connectionID,
            planID: connection.planID,
            revision: plan.revision,
            title: plan.title,
            effectiveStart: updatedAt,
            effectiveEnd: Calendar.current.date(byAdding: .day, value: 6, to: updatedAt),
            planJSON: MealPlanDemoFactory.encodedPlan(),
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    private func resetLocalData() {
        isShowingProfile = false
        Task { @MainActor in
            await CheckInReminderScheduler.cancelAll()
        }
        checkIns.forEach(modelContext.delete)
        weightEntries.forEach(modelContext.delete)
        measurementEntries.forEach(modelContext.delete)
        earnedAchievements.forEach(modelContext.delete)
        challenges.forEach(modelContext.delete)
        nutritionistConnections.forEach(modelContext.delete)
        mealPlanCaches.forEach(modelContext.delete)
        goals.forEach(modelContext.delete)
        modelContext.delete(profile)
        try? modelContext.save()
    }

    private func routeToCheckInReminder() {
        goalSheet = nil
        challengeSheet = nil
        isAddingPastWeight = false
        isAddingMeasurements = false
        isShowingAchievements = false
        isShowingAchievementUnlock = false
        pendingAchievementUnlocks = []
        isShowingProfile = false
        selectedTab = .today
        isCheckingIn = metrics.todayCheckIn == nil
        notificationRouter.consumeCheckInReminderRoute()
    }

    private func deleteExtraGoal(_ goal: Goal) {
        guard !goal.core else { return }
        modelContext.delete(goal)
        try? modelContext.save()
    }

    private func saveChallenge(_ values: ChallengeFormValues) {
        saveChallenge(values, existing: nil)
    }

    private func saveChallenge(_ values: ChallengeFormValues, existing: Challenge?) {
        if values.isPinned {
            unpinOtherChallenges(except: existing?.id)
        }

        if let existing {
            existing.title = values.title
            existing.kind = values.kind
            existing.startDate = Calendar.current.startOfDay(for: values.startDate)
            existing.endDate = Calendar.current.startOfDay(for: values.endDate)
            existing.targetValue = values.targetValue
            existing.baselineWeight = values.baselineWeight
            existing.unit = values.unit
            existing.isPinned = values.isPinned
            existing.completedAt = nil
            existing.archivedAt = nil
            existing.updatedAt = Date()
        } else {
            modelContext.insert(
                Challenge(
                    title: values.title,
                    kind: values.kind,
                    startDate: values.startDate,
                    endDate: values.endDate,
                    targetValue: values.targetValue,
                    baselineWeight: values.baselineWeight,
                    unit: values.unit,
                    isPinned: values.isPinned
                )
            )
        }

        refreshChallenges()
        try? modelContext.save()
        challengeSheet = nil
    }

    private func toggleChallengePin(_ challenge: Challenge) {
        guard metrics.progress(for: challenge).isActive else { return }
        if challenge.isPinned {
            challenge.isPinned = false
        } else {
            unpinOtherChallenges(except: challenge.id)
            challenge.isPinned = true
        }
        challenge.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteChallenge(_ challenge: Challenge) {
        modelContext.delete(challenge)
        try? modelContext.save()
    }

    private func unpinOtherChallenges(except id: UUID?) {
        for challenge in challenges where challenge.id != id && challenge.isPinned {
            challenge.isPinned = false
            challenge.updatedAt = Date()
        }
    }

    private func refreshChallenges() {
        let fetchedCheckIns = (try? modelContext.fetch(FetchDescriptor<DailyCheckIn>())) ?? checkIns
        let fetchedWeights = (try? modelContext.fetch(FetchDescriptor<WeightEntry>())) ?? weightEntries
        let fetchedChallenges = (try? modelContext.fetch(FetchDescriptor<Challenge>())) ?? challenges
        let freshMetrics = TrackerMetrics(
            profile: profile,
            checkIns: fetchedCheckIns,
            weightEntries: fetchedWeights,
            measurementEntries: measurementEntries,
            goals: goals,
            challenges: fetchedChallenges,
            earnedAchievements: earnedAchievements,
            displayedMonth: displayedMonth
        )

        for challenge in fetchedChallenges where challenge.archivedAt == nil {
            let progress = freshMetrics.progress(for: challenge)
            if progress.state == .completed, challenge.completedAt == nil {
                challenge.completedAt = Date()
                challenge.isPinned = false
                challenge.updatedAt = Date()
            } else if progress.state == .finished, challenge.isPinned {
                challenge.isPinned = false
                challenge.updatedAt = Date()
            }
        }
    }

    private func shiftedMonth(by value: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func saveWeightEntry(date: Date, weight: Double) {
        upsertWeightEntry(on: date, weight: weight)
        ensureCoreGoals()
        refreshGoals()
        refreshChallenges()
        try? modelContext.save()
        isAddingPastWeight = false
        evaluateAchievements(presentsUnlocks: true)
    }

    private func saveBodyMeasurementEntry(_ snapshot: BodyMeasurementSnapshot) {
        upsertBodyMeasurementEntry(on: Date(), snapshot: snapshot)
        try? modelContext.save()
        isAddingMeasurements = false
        evaluateAchievements(presentsUnlocks: true)
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

    private func upsertBodyMeasurementEntry(on date: Date, snapshot: BodyMeasurementSnapshot) {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = bodyMeasurementEntry(on: day) {
            existing.chest = snapshot.chest
            existing.waist = snapshot.waist
            existing.hips = snapshot.hips
            existing.unit = snapshot.unit
            existing.updatedAt = Date()
        } else {
            modelContext.insert(
                BodyMeasurementEntry(
                    date: day,
                    chest: snapshot.chest,
                    waist: snapshot.waist,
                    hips: snapshot.hips,
                    unit: snapshot.unit
                )
            )
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

    private func backfillBodyMeasurementEntries() {
        guard measurementEntries.isEmpty else { return }
        let snapshot = BodyMeasurementSnapshot(
            chest: profile.chestMeasurement,
            waist: profile.waistMeasurement,
            hips: profile.hipsMeasurement,
            unit: profile.bodyMeasurementUnit
        )
        guard snapshot.hasAnyValue else { return }

        modelContext.insert(
            BodyMeasurementEntry(
                date: profile.createdAt,
                chest: snapshot.chest,
                waist: snapshot.waist,
                hips: snapshot.hips,
                unit: snapshot.unit,
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt
            )
        )
        try? modelContext.save()
    }

    private func weightEntry(on date: Date) -> WeightEntry? {
        let day = Calendar.current.startOfDay(for: date)
        return weightEntries.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func bodyMeasurementEntry(on date: Date) -> BodyMeasurementEntry? {
        let day = Calendar.current.startOfDay(for: date)
        return measurementEntries.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
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

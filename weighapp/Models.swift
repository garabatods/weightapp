import Foundation
import SwiftData

enum DietStatus: String, CaseIterable, Identifiable, Codable {
    case yes
    case mostly
    case no
    case flex

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yes: "Yes"
        case .mostly: "Mostly"
        case .no: "No"
        case .flex: "Flex"
        }
    }

    static let standardOptions: [DietStatus] = [.yes, .mostly, .no]
}

enum FlexWeekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var bit: Int {
        1 << (rawValue - 1)
    }

    var shortLabel: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }

    static func mask(for weekdays: [FlexWeekday]) -> Int {
        weekdays.reduce(0) { $0 | $1.bit }
    }

    static func selected(in mask: Int) -> [FlexWeekday] {
        allCases.filter { mask & $0.bit != 0 }
    }

    static func summary(for mask: Int, enabled: Bool) -> String {
        guard enabled else { return "Off" }
        let labels = selected(in: mask).map(\.shortLabel)
        return labels.isEmpty ? "No days selected" : labels.joined(separator: ", ")
    }
}

enum GoalType: String, CaseIterable, Identifiable, Codable {
    case dietDays = "diet_days"
    case weightTarget = "weight_target"
    case movementDays = "movement_days"
    case weighIns = "weigh_ins"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dietDays: "On-plan days"
        case .weightTarget: "Reach target weight"
        case .movementDays: "Movement days"
        case .weighIns: "Weight logs"
        }
    }
}

enum GoalPeriod: String, CaseIterable, Identifiable, Codable {
    case week
    case month
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .custom: "Custom"
        }
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
}

enum NutritionistConnectionStatus: String, Codable {
    case active
    case expired
    case revoked

    var label: String {
        switch self {
        case .active: "Active"
        case .expired: "Expired"
        case .revoked: "Revoked"
        }
    }
}

enum ChallengeKind: String, CaseIterable, Identifiable, Codable {
    case checkInDays = "check_in_days"
    case weightLoss = "weight_loss"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .checkInDays: "Check-in days"
        case .weightLoss: "Weight loss"
        }
    }

    var symbol: String {
        switch self {
        case .checkInDays: "calendar.badge.checkmark"
        case .weightLoss: "scalemass"
        }
    }

    var tone: IconTone {
        switch self {
        case .checkInDays: .success
        case .weightLoss: .info
        }
    }
}

enum ChallengeState {
    case active
    case completed
    case finished
}

enum BodyMeasurementUnit: String, CaseIterable, Identifiable, Codable {
    case centimeters = "cm"
    case inches = "in"

    var id: String { rawValue }

    static func defaultUnit(forWeightUnit weightUnit: String) -> BodyMeasurementUnit {
        weightUnit == "lb" ? .inches : .centimeters
    }
}

enum BodyMeasurementMetric: String, CaseIterable, Identifiable {
    case chest
    case waist
    case hips

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chest: "Chest"
        case .waist: "Waist"
        case .hips: "Hips"
        }
    }
}

enum TrendRange: String, CaseIterable, Identifiable {
    case sixWeeks = "6W"
    case threeMonths = "3M"
    case all = "All"

    var id: String { rawValue }
}

struct AchievementDefinition: Identifiable {
    let key: String
    let title: String
    let subtitle: String
    let symbol: String
    let tone: IconTone

    var id: String { key }
}

enum AchievementCatalog {
    static let definitions: [AchievementDefinition] = [
        AchievementDefinition(
            key: "first_check_in",
            title: "First check-in",
            subtitle: "You showed up once. That counts.",
            symbol: "checkmark.circle.fill",
            tone: .success
        ),
        AchievementDefinition(
            key: "first_weight_log",
            title: "First weight log",
            subtitle: "Your trend has a starting point.",
            symbol: "scalemass",
            tone: .info
        ),
        AchievementDefinition(
            key: "steady_week",
            title: "Steady week",
            subtitle: "A week with real check-ins.",
            symbol: "calendar.badge.checkmark",
            tone: .success
        ),
        AchievementDefinition(
            key: "on_plan_week",
            title: "On-plan week",
            subtitle: "You hit your weekly diet target.",
            symbol: "flag.fill",
            tone: .primary
        ),
        AchievementDefinition(
            key: "movement_month",
            title: "Movement rhythm",
            subtitle: "Movement showed up across the month.",
            symbol: "shoeprints.fill",
            tone: .movement
        ),
        AchievementDefinition(
            key: "trend_builder",
            title: "Trend builder",
            subtitle: "Enough weigh-ins to see a pattern.",
            symbol: "chart.line.uptrend.xyaxis",
            tone: .info
        ),
        AchievementDefinition(
            key: "measurement_trend",
            title: "Beyond the scale",
            subtitle: "Measurements are becoming a trend.",
            symbol: "ruler",
            tone: .measurement
        ),
        AchievementDefinition(
            key: "three_month_rhythm",
            title: "3-month rhythm",
            subtitle: "Your habits have history now.",
            symbol: "calendar",
            tone: .primary
        ),
        AchievementDefinition(
            key: "six_month_rhythm",
            title: "6-month rhythm",
            subtitle: "Half a year of showing up.",
            symbol: "leaf.fill",
            tone: .success
        ),
        AchievementDefinition(
            key: "year_of_showing_up",
            title: "Year of small steps",
            subtitle: "A full year of consistency work.",
            symbol: "sparkles",
            tone: .warning
        )
    ]

    static var totalCount: Int {
        definitions.count
    }

    static func definition(for key: String) -> AchievementDefinition? {
        definitions.first { $0.key == key }
    }

    static func contains(_ key: String) -> Bool {
        definition(for: key) != nil
    }

    static func index(for key: String) -> Int {
        definitions.firstIndex { $0.key == key } ?? definitions.count
    }
}

struct BodyMeasurementSnapshot {
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var unit: String

    var hasAnyValue: Bool {
        chest != nil || waist != nil || hips != nil
    }

    func value(for metric: BodyMeasurementMetric) -> Double? {
        switch metric {
        case .chest: chest
        case .waist: waist
        case .hips: hips
        }
    }
}

enum BodyMeasurementUnitConverter {
    static func converted(_ value: Double, from oldUnit: String, to newUnit: String) -> Double {
        guard oldUnit != newUnit else { return value }
        if oldUnit == BodyMeasurementUnit.centimeters.rawValue && newUnit == BodyMeasurementUnit.inches.rawValue {
            return value / 2.54
        }
        if oldUnit == BodyMeasurementUnit.inches.rawValue && newUnit == BodyMeasurementUnit.centimeters.rawValue {
            return value * 2.54
        }
        return value
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var startingWeight: Double
    var currentWeight: Double
    var goalWeight: Double
    var unit: String
    var weeklyDietTarget: Int
    var weeklyMovementTarget: Int
    var weeklyWeighInTarget: Int
    var displayName: String?
    @Attribute(.externalStorage) var profileImageData: Data?
    var checkInReminderEnabledValue: Bool?
    var checkInReminderHourValue: Int?
    var checkInReminderMinuteValue: Int?
    var flexDaysEnabledValue: Bool?
    var flexWeekdayMaskValue: Int?
    var chestMeasurementValue: Double?
    var waistMeasurementValue: Double?
    var hipsMeasurementValue: Double?
    var bodyMeasurementUnitValue: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        startingWeight: Double,
        currentWeight: Double,
        goalWeight: Double,
        unit: String = "kg",
        weeklyDietTarget: Int = 5,
        weeklyMovementTarget: Int = 3,
        weeklyWeighInTarget: Int = 3,
        displayName: String? = nil,
        profileImageData: Data? = nil,
        checkInReminderEnabled: Bool = false,
        checkInReminderHour: Int = CheckInReminderDefaults.hour,
        checkInReminderMinute: Int = CheckInReminderDefaults.minute,
        flexDaysEnabled: Bool = false,
        flexWeekdayMask: Int = 0,
        chestMeasurement: Double? = nil,
        waistMeasurement: Double? = nil,
        hipsMeasurement: Double? = nil,
        bodyMeasurementUnit: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.startingWeight = startingWeight
        self.currentWeight = currentWeight
        self.goalWeight = goalWeight
        self.unit = unit
        self.weeklyDietTarget = weeklyDietTarget
        self.weeklyMovementTarget = weeklyMovementTarget
        self.weeklyWeighInTarget = weeklyWeighInTarget
        self.displayName = displayName
        self.profileImageData = profileImageData
        self.checkInReminderEnabledValue = checkInReminderEnabled
        self.checkInReminderHourValue = checkInReminderHour
        self.checkInReminderMinuteValue = checkInReminderMinute
        self.flexDaysEnabledValue = flexDaysEnabled
        self.flexWeekdayMaskValue = flexWeekdayMask
        self.chestMeasurementValue = chestMeasurement
        self.waistMeasurementValue = waistMeasurement
        self.hipsMeasurementValue = hipsMeasurement
        self.bodyMeasurementUnitValue = bodyMeasurementUnit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var checkInReminderEnabled: Bool {
        get { checkInReminderEnabledValue ?? false }
        set { checkInReminderEnabledValue = newValue }
    }

    var checkInReminderHour: Int {
        get { checkInReminderHourValue ?? CheckInReminderDefaults.hour }
        set { checkInReminderHourValue = min(max(newValue, 0), 23) }
    }

    var checkInReminderMinute: Int {
        get { checkInReminderMinuteValue ?? CheckInReminderDefaults.minute }
        set { checkInReminderMinuteValue = min(max(newValue, 0), 59) }
    }

    var flexDaysEnabled: Bool {
        get { flexDaysEnabledValue ?? false }
        set { flexDaysEnabledValue = newValue }
    }

    var flexWeekdayMask: Int {
        get { flexWeekdayMaskValue ?? 0 }
        set { flexWeekdayMaskValue = min(max(newValue, 0), 127) }
    }

    var flexWeekdayCount: Int {
        FlexWeekday.selected(in: flexWeekdayMask).count
    }

    var flexDaysSummary: String {
        FlexWeekday.summary(for: flexWeekdayMask, enabled: flexDaysEnabled)
    }

    var chestMeasurement: Double? {
        get { chestMeasurementValue }
        set { chestMeasurementValue = newValue }
    }

    var waistMeasurement: Double? {
        get { waistMeasurementValue }
        set { waistMeasurementValue = newValue }
    }

    var hipsMeasurement: Double? {
        get { hipsMeasurementValue }
        set { hipsMeasurementValue = newValue }
    }

    var bodyMeasurementUnit: String {
        get {
            let fallback = BodyMeasurementUnit.defaultUnit(forWeightUnit: unit).rawValue
            guard let rawValue = bodyMeasurementUnitValue,
                  BodyMeasurementUnit(rawValue: rawValue) != nil else {
                return fallback
            }
            return rawValue
        }
        set {
            bodyMeasurementUnitValue = BodyMeasurementUnit(rawValue: newValue)?.rawValue
        }
    }

    func isPlannedFlexDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard flexDaysEnabled, flexWeekdayMask != 0 else { return false }
        guard let weekday = FlexWeekday(rawValue: calendar.component(.weekday, from: date)) else { return false }
        return flexWeekdayMask & weekday.bit != 0
    }
}

@Model
final class BodyMeasurementEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var unit: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        chest: Double? = nil,
        waist: Double? = nil,
        hips: Double? = nil,
        unit: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.chest = chest
        self.waist = waist
        self.hips = hips
        self.unit = BodyMeasurementUnit(rawValue: unit)?.rawValue ?? BodyMeasurementUnit.centimeters.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var snapshot: BodyMeasurementSnapshot {
        BodyMeasurementSnapshot(chest: chest, waist: waist, hips: hips, unit: unit)
    }

    func value(for metric: BodyMeasurementMetric) -> Double? {
        snapshot.value(for: metric)
    }
}

enum CheckInReminderDefaults {
    static let hour = 20
    static let minute = 0

    static func date(
        hour: Int = CheckInReminderDefaults.hour,
        minute: Int = CheckInReminderDefaults.minute
    ) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    static func components(from date: Date) -> (hour: Int, minute: Int) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? hour, components.minute ?? minute)
    }

    static func timeText(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date(hour: hour, minute: minute))
    }
}

@Model
final class DailyCheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var dietStatusRaw: String
    var moved: Bool
    var weight: Double?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        dietStatus: DietStatus,
        moved: Bool,
        weight: Double?,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.dietStatusRaw = dietStatus.rawValue
        self.moved = moved
        self.weight = weight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var dietStatus: DietStatus {
        get { DietStatus(rawValue: dietStatusRaw) ?? .no }
        set { dietStatusRaw = newValue.rawValue }
    }
}

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        weight: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var title: String
    var targetValue: Double
    var currentValue: Double
    var periodRaw: String
    var statusRaw: String
    var isCore: Bool?
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        type: GoalType,
        title: String,
        targetValue: Double,
        currentValue: Double = 0,
        period: GoalPeriod,
        isCore: Bool = false,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.periodRaw = period.rawValue
        self.isCore = isCore
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .dietDays }
        set { typeRaw = newValue.rawValue }
    }

    var period: GoalPeriod {
        get { GoalPeriod(rawValue: periodRaw) ?? .week }
        set { periodRaw = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var core: Bool {
        get { isCore ?? false }
        set { isCore = newValue }
    }
}

@Model
final class Challenge {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String
    var startDate: Date
    var endDate: Date
    var targetValue: Double
    var baselineWeight: Double?
    var unit: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        kind: ChallengeKind,
        startDate: Date,
        endDate: Date,
        targetValue: Double,
        baselineWeight: Double? = nil,
        unit: String,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        archivedAt: Date? = nil
    ) {
        let calendar = Calendar.current
        self.id = id
        self.title = title
        self.kindRaw = kind.rawValue
        self.startDate = calendar.startOfDay(for: startDate)
        self.endDate = calendar.startOfDay(for: endDate)
        self.targetValue = targetValue
        self.baselineWeight = baselineWeight
        self.unit = unit
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.archivedAt = archivedAt
    }

    var kind: ChallengeKind {
        get { ChallengeKind(rawValue: kindRaw) ?? .checkInDays }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class NutritionistConnection {
    @Attribute(.unique) var id: UUID
    var connectionID: String
    var nutritionistDisplayName: String
    var planID: String
    var statusRaw: String
    var accessToken: String
    var pairedAt: Date
    var lastSyncAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        connectionID: String,
        nutritionistDisplayName: String,
        planID: String,
        status: NutritionistConnectionStatus = .active,
        accessToken: String,
        pairedAt: Date = Date(),
        lastSyncAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.connectionID = connectionID
        self.nutritionistDisplayName = nutritionistDisplayName
        self.planID = planID
        self.statusRaw = status.rawValue
        self.accessToken = accessToken
        self.pairedAt = pairedAt
        self.lastSyncAt = lastSyncAt
        self.updatedAt = updatedAt
    }

    var status: NutritionistConnectionStatus {
        get { NutritionistConnectionStatus(rawValue: statusRaw) ?? .expired }
        set { statusRaw = newValue.rawValue }
    }
}

@Model
final class MealPlanCache {
    @Attribute(.unique) var id: UUID
    var connectionID: String
    var planID: String
    var revision: Int
    var title: String
    var effectiveStart: Date
    var effectiveEnd: Date?
    var planJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        connectionID: String,
        planID: String,
        revision: Int,
        title: String,
        effectiveStart: Date,
        effectiveEnd: Date? = nil,
        planJSON: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.connectionID = connectionID
        self.planID = planID
        self.revision = revision
        self.title = title
        self.effectiveStart = Calendar.current.startOfDay(for: effectiveStart)
        self.effectiveEnd = effectiveEnd.map { Calendar.current.startOfDay(for: $0) }
        self.planJSON = planJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var plan: MealPlan? {
        guard let data = planJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MealPlan.self, from: data)
    }
}

struct UserProgress {
    let startingWeight: Double
    let currentWeight: Double
    let goalWeight: Double
    let unit: String
    let currentStreak: Int
    let bestStreak: Int

    var totalLost: Double {
        startingWeight - currentWeight
    }

    var remainingWeight: Double {
        max(currentWeight - goalWeight, 0)
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let weight: Double
}

struct MealPlan: Codable {
    var title: String
    var revision: Int
    var effectiveSummary: String
    var overviewNote: String
    var days: [MealPlanDay]
}

struct MealPlanDay: Codable, Identifiable {
    var id: String
    var title: String
    var meals: [MealPlanMeal]

    var shortTitle: String {
        String(title.prefix(3))
    }
}

struct MealPlanMeal: Codable, Identifiable {
    var id: String
    var title: String
    var time: String
    var items: [String]
    var swaps: [String]
    var note: String?
}

enum MealPlanDemoFactory {
    static func plan() -> MealPlan {
        MealPlan(
            title: "Steady Week Support Plan",
            revision: 1,
            effectiveSummary: "This week",
            overviewNote: "Meal plans are provided by your nutritionist. Use this as read-only guidance for timing, portions, swaps, and notes. Leafstep keeps your habit check-ins and weight history on this device.",
            days: [
                MealPlanDay(
                    id: "monday",
                    title: "Monday",
                    meals: [
                        meal(id: "mon-breakfast", title: "Breakfast", time: "8:00 AM", items: ["Greek yogurt bowl", "Berries", "Chia seeds", "Water or unsweet tea"], swaps: ["Swap yogurt for cottage cheese if preferred."], note: "Keep this one simple and repeatable."),
                        meal(id: "mon-lunch", title: "Lunch", time: "12:30 PM", items: ["Chicken salad wrap", "Cucumber slices", "Side of fruit"], swaps: ["Use tofu, tuna, or turkey instead of chicken."], note: nil),
                        meal(id: "mon-dinner", title: "Dinner", time: "6:30 PM", items: ["Salmon plate", "Roasted vegetables", "Small rice portion"], swaps: ["Swap salmon for beans, turkey, or eggs."], note: "Stop when comfortably satisfied.")
                    ]
                ),
                MealPlanDay(
                    id: "tuesday",
                    title: "Tuesday",
                    meals: [
                        meal(id: "tue-breakfast", title: "Breakfast", time: "8:00 AM", items: ["Egg scramble", "Spinach", "Whole-grain toast"], swaps: ["Swap eggs for tofu scramble."], note: nil),
                        meal(id: "tue-lunch", title: "Lunch", time: "12:30 PM", items: ["Turkey bowl", "Greens", "Avocado", "Salsa"], swaps: ["Use beans for a vegetarian option."], note: "Build the bowl around the portion guide you reviewed together."),
                        meal(id: "tue-dinner", title: "Dinner", time: "6:30 PM", items: ["Lean protein", "Two vegetables", "Small potato"], swaps: ["Use the protein option your nutritionist approved."], note: "This is guidance, not a tracker.")
                    ]
                ),
                MealPlanDay(
                    id: "wednesday",
                    title: "Wednesday",
                    meals: [
                        meal(id: "wed-breakfast", title: "Breakfast", time: "7:45 AM", items: ["Overnight oats", "Berries", "Plain yogurt"], swaps: ["Swap oats for whole-grain toast with nut butter."], note: "Prep this the night before if mornings are rushed."),
                        meal(id: "wed-lunch", title: "Lunch", time: "12:15 PM", items: ["Lentil soup", "Side salad", "Whole-grain crackers"], swaps: ["Swap soup for chicken vegetable soup."], note: nil),
                        meal(id: "wed-dinner", title: "Dinner", time: "6:45 PM", items: ["Chicken fajita plate", "Peppers and onions", "Beans or rice portion"], swaps: ["Use shrimp, tofu, or mushrooms for the main protein."], note: "Choose one starchy side unless your nutritionist changes the plan.")
                    ]
                ),
                MealPlanDay(
                    id: "thursday",
                    title: "Thursday",
                    meals: [
                        meal(id: "thu-breakfast", title: "Breakfast", time: "8:00 AM", items: ["Protein smoothie", "Spinach", "Frozen berries", "Nut butter portion"], swaps: ["Use kefir or lactose-free milk if preferred."], note: nil),
                        meal(id: "thu-lunch", title: "Lunch", time: "12:30 PM", items: ["Tuna salad plate", "Greens", "Tomatoes", "Whole-grain toast"], swaps: ["Swap tuna for chickpea salad."], note: "Keep dressings measured using your nutritionist's portion guide."),
                        meal(id: "thu-dinner", title: "Dinner", time: "6:30 PM", items: ["Turkey meatballs", "Zucchini or mixed vegetables", "Small pasta portion"], swaps: ["Swap turkey for lentil meatballs."], note: nil)
                    ]
                ),
                MealPlanDay(
                    id: "friday",
                    title: "Friday",
                    meals: [
                        meal(id: "fri-breakfast", title: "Breakfast", time: "8:15 AM", items: ["Cottage cheese bowl", "Peach or berries", "Pumpkin seeds"], swaps: ["Swap cottage cheese for Greek yogurt."], note: nil),
                        meal(id: "fri-lunch", title: "Lunch", time: "12:30 PM", items: ["Chicken quinoa salad", "Greens", "Cucumber", "Light vinaigrette"], swaps: ["Use tofu or beans instead of chicken."], note: "Pack this ahead if the afternoon gets busy."),
                        meal(id: "fri-dinner", title: "Dinner", time: "7:00 PM", items: ["Restaurant-style plate", "Lean protein", "Vegetable side", "One chosen starch"], swaps: ["If eating out, choose grilled, roasted, or steamed options."], note: "Use the plan as a guide, not a pass/fail test.")
                    ]
                ),
                MealPlanDay(
                    id: "saturday",
                    title: "Saturday",
                    meals: [
                        meal(id: "sat-breakfast", title: "Breakfast", time: "8:30 AM", items: ["Veggie omelet", "Fruit", "Whole-grain toast"], swaps: ["Swap omelet for tofu scramble."], note: nil),
                        meal(id: "sat-lunch", title: "Lunch", time: "1:00 PM", items: ["Turkey lettuce wraps", "Carrot sticks", "Hummus portion"], swaps: ["Use grilled chicken, tofu, or beans."], note: nil),
                        meal(id: "sat-dinner", title: "Dinner", time: "6:30 PM", items: ["Build-your-plate dinner", "Half plate vegetables", "Protein portion", "Small starch portion"], swaps: ["Use your approved home or restaurant option."], note: "A flexible meal can still follow the structure.")
                    ]
                ),
                MealPlanDay(
                    id: "sunday",
                    title: "Sunday",
                    meals: [
                        meal(id: "sun-breakfast", title: "Breakfast", time: "8:30 AM", items: ["Greek yogurt parfait", "Berries", "Low-sugar granola portion"], swaps: ["Swap parfait for eggs and toast."], note: nil),
                        meal(id: "sun-lunch", title: "Lunch", time: "12:45 PM", items: ["Meal-prep bowl", "Protein choice", "Greens", "Roasted vegetables"], swaps: ["Use leftovers from Saturday dinner."], note: "Notice what meals felt easiest this week."),
                        meal(id: "sun-dinner", title: "Dinner", time: "6:00 PM", items: ["Simple soup or chili", "Side salad", "Fruit"], swaps: ["Use bean chili, turkey chili, or vegetable soup."], note: "Prep one breakfast or lunch component for tomorrow.")
                    ]
                )
            ]
        )
    }

    private static func meal(id: String, title: String, time: String, items: [String], swaps: [String], note: String?) -> MealPlanMeal {
        MealPlanMeal(
            id: id,
            title: title,
            time: time,
            items: items,
            swaps: swaps,
            note: note
        )
    }

    static func encodedPlan() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(plan()) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

struct ChallengeProgress {
    let challenge: Challenge
    let state: ChallengeState
    let currentValue: Double
    let targetValue: Double
    let unit: String?
    let detail: String

    var isActive: Bool {
        state == .active
    }

    var progressValue: Double {
        min(max(currentValue, 0), targetValue)
    }

    var progressText: String {
        switch challenge.kind {
        case .checkInDays:
            "\(Int(progressValue)) / \(Int(targetValue)) check-ins"
        case .weightLoss:
            "\(Self.numberText(progressValue)) / \(Self.numberText(targetValue)) \(unit ?? challenge.unit)"
        }
    }

    var stateLabel: String {
        switch state {
        case .active:
            "Challenge"
        case .completed:
            "Completed"
        case .finished:
            "Finished"
        }
    }

    static func numberText(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

@Model
final class EarnedAchievement {
    @Attribute(.unique) var key: String
    var earnedAt: Date
    var createdAt: Date

    init(key: String, earnedAt: Date = Date(), createdAt: Date = Date()) {
        self.key = key
        self.earnedAt = earnedAt
        self.createdAt = createdAt
    }
}

enum CalendarDayStatus {
    case onPlan
    case mostly
    case missed
    case flex
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let day: Int
    let isCurrentMonth: Bool
    let status: CalendarDayStatus?
    let isPlannedFlexDay: Bool
    let hasWeighIn: Bool
}

struct TrackerMetrics {
    let profile: UserProfile
    let checkIns: [DailyCheckIn]
    let weightEntries: [WeightEntry]
    let measurementEntries: [BodyMeasurementEntry]
    let goals: [Goal]
    let challenges: [Challenge]
    let earnedAchievements: [EarnedAchievement]
    var displayedMonth: Date = Date()

    private var calendar: Calendar {
        Calendar.current
    }

    var todayCheckIn: DailyCheckIn? {
        checkIn(on: Date())
    }

    var progress: UserProgress {
        UserProgress(
            startingWeight: profile.startingWeight,
            currentWeight: latestWeight,
            goalWeight: profile.goalWeight,
            unit: profile.unit,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }

    var latestWeight: Double {
        latestWeightEntry?.weight ?? profile.currentWeight
    }

    var weeklyDietCount: Int {
        checkInsThisWeek.filter { $0.dietStatus == .yes }.count
    }

    var weeklyMovementCount: Int {
        checkInsThisWeek.filter(\.moved).count
    }

    var weeklyWeighInCount: Int {
        weightEntriesThisWeek.count
    }

    var monthlyOnPlanCount: Int {
        checkInsThisMonth.filter { $0.dietStatus == .yes }.count
    }

    var monthlyWeighInCount: Int {
        weightEntriesThisMonth.count
    }

    var monthlyConsistency: Int {
        guard monthlyEligibleCheckInCount > 0 else { return 0 }
        return min(Int((Double(monthlyOnPlanCount) / Double(monthlyEligibleCheckInCount) * 100).rounded()), 100)
    }

    var monthlyEligibleCheckInCount: Int {
        checkInsThisMonth.filter { $0.dietStatus != .flex }.count
    }

    var hasFlexCheckInsThisMonth: Bool {
        checkInsThisMonth.contains { $0.dietStatus == .flex }
    }

    var plannedFlexDaysThisWeek: Int {
        profile.flexDaysEnabled ? profile.flexWeekdayCount : 0
    }

    var isTodayPlannedFlexDay: Bool {
        profile.isPlannedFlexDay(Date(), calendar: calendar)
    }

    var earnedAchievementKeys: Set<String> {
        Set(earnedAchievements.map(\.key).filter(AchievementCatalog.contains))
    }

    var earnedAchievementCount: Int {
        earnedAchievementKeys.count
    }

    var latestEarnedAchievements: [AchievementDefinition] {
        earnedAchievements
            .sorted {
                if $0.earnedAt == $1.earnedAt {
                    return AchievementCatalog.index(for: $0.key) < AchievementCatalog.index(for: $1.key)
                }
                return $0.earnedAt > $1.earnedAt
            }
            .compactMap { AchievementCatalog.definition(for: $0.key) }
    }

    var achievementProgressSummary: String {
        "\(earnedAchievementCount) of \(AchievementCatalog.totalCount) earned"
    }

    var activeChallengeProgress: [ChallengeProgress] {
        challengeProgressCards
            .filter(\.isActive)
            .sorted { lhs, rhs in
                if lhs.challenge.isPinned != rhs.challenge.isPinned {
                    return lhs.challenge.isPinned
                }
                return lhs.challenge.createdAt < rhs.challenge.createdAt
            }
    }

    var finishedChallengeProgress: [ChallengeProgress] {
        challengeProgressCards
            .filter { !$0.isActive }
            .sorted { lhs, rhs in
                let lhsDate = lhs.challenge.completedAt ?? lhs.challenge.endDate
                let rhsDate = rhs.challenge.completedAt ?? rhs.challenge.endDate
                return lhsDate > rhsDate
            }
    }

    var pinnedChallengeProgress: ChallengeProgress? {
        activeChallengeProgress.first { $0.challenge.isPinned }
    }

    var activeChallengeCount: Int {
        activeChallengeProgress.count
    }

    var latestMeasurementEntry: BodyMeasurementEntry? {
        measurementEntries
            .sorted {
                if calendar.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.updatedAt < $1.updatedAt
                }
                return $0.date < $1.date
            }
            .last
    }

    var latestMeasurementSnapshot: BodyMeasurementSnapshot? {
        if let latestMeasurementEntry {
            return latestMeasurementEntry.snapshot
        }

        let snapshot = BodyMeasurementSnapshot(
            chest: profile.chestMeasurement,
            waist: profile.waistMeasurement,
            hips: profile.hipsMeasurement,
            unit: profile.bodyMeasurementUnit
        )
        return snapshot.hasAnyValue ? snapshot : nil
    }

    func trendPoints(for range: TrendRange) -> [TrendPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let weighted = filteredWeightEntries(for: range)
            .sorted { $0.date < $1.date }

        if weighted.isEmpty {
            return [TrendPoint(label: formatter.string(from: Date()), weight: latestWeight)]
        }

        return weighted.map { entry in
            TrendPoint(label: formatter.string(from: entry.date), weight: entry.weight)
        }
    }

    func measurementTrendPoints(for metric: BodyMeasurementMetric, range: TrendRange) -> [TrendPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return filteredMeasurementEntries(for: range)
            .sorted { $0.date < $1.date }
            .compactMap { entry in
                guard let value = entry.value(for: metric) else { return nil }
                return TrendPoint(label: formatter.string(from: entry.date), weight: value)
            }
    }

    func measurementChange(for metric: BodyMeasurementMetric) -> Double? {
        let values = measurementEntries
            .sorted { $0.date < $1.date }
            .compactMap { $0.value(for: metric) }
        guard let first = values.first, let last = values.last, values.count > 1 else { return nil }
        return last - first
    }

    var calendarMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var calendarDays: [CalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let prefixCount = max(firstWeekday - calendar.firstWeekday, 0)
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        let previousRange = calendar.range(of: .day, in: .month, for: previousMonth) ?? 1..<1
        let previousDays = Array(previousRange).suffix(prefixCount)

        var days = previousDays.map {
            CalendarDay(day: $0, isCurrentMonth: false, status: nil, isPlannedFlexDay: false, hasWeighIn: false)
        }

        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else { continue }
            let checkIn = checkIn(on: date)
            let weightEntry = weightEntry(on: date)
            let isPlannedFlexDay = profile.isPlannedFlexDay(date, calendar: calendar)
            let status = checkIn.map(calendarStatus)
            days.append(
                CalendarDay(
                    day: day,
                    isCurrentMonth: true,
                    status: status,
                    isPlannedFlexDay: isPlannedFlexDay,
                    hasWeighIn: weightEntry != nil
                )
            )
        }

        let nextDayCount = (7 - (days.count % 7)) % 7
        if nextDayCount > 0 {
            days += (1...nextDayCount).map {
                CalendarDay(day: $0, isCurrentMonth: false, status: nil, isPlannedFlexDay: false, hasWeighIn: false)
            }
        }

        return days
    }

    var coreGoalCards: [(goal: Goal, mode: GoalCardMode, isCompleted: Bool)] {
        GoalType.allCases.compactMap { type in
            guard let goal = goals.first(where: { $0.core && $0.type == type }) else { return nil }
            return (goal, mode(for: goal), displayStatus(for: goal) == .completed)
        }
    }

    var extraActiveGoalCards: [(goal: Goal, mode: GoalCardMode)] {
        goals
            .filter { !$0.core && displayStatus(for: $0) == .active }
            .sorted { $0.createdAt < $1.createdAt }
            .map { ($0, mode(for: $0)) }
    }

    var extraCompletedGoalCards: [(goal: Goal, mode: GoalCardMode)] {
        goals
            .filter { !$0.core && displayStatus(for: $0) == .completed }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
            .map { ($0, mode(for: $0)) }
    }

    var activeGoalCards: [(goal: Goal, mode: GoalCardMode)] {
        extraActiveGoalCards
    }

    var completedGoalCards: [(goal: Goal, mode: GoalCardMode)] {
        extraCompletedGoalCards
    }

    func checkIn(on date: Date) -> DailyCheckIn? {
        let day = calendar.startOfDay(for: date)
        return checkIns.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func weightEntry(on date: Date) -> WeightEntry? {
        let day = calendar.startOfDay(for: date)
        return weightEntries.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func measurementEntry(on date: Date) -> BodyMeasurementEntry? {
        let day = calendar.startOfDay(for: date)
        return measurementEntries.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func currentValue(for goal: Goal) -> Double {
        let sourceCheckIns = checkIns(for: goal.period)
        return switch goal.type {
        case .dietDays:
            Double(sourceCheckIns.filter { $0.dietStatus == .yes }.count)
        case .weightTarget:
            latestWeight
        case .movementDays:
            Double(sourceCheckIns.filter(\.moved).count)
        case .weighIns:
            Double(weightEntries(for: goal.period).count)
        }
    }

    func displayStatus(for goal: Goal) -> GoalStatus {
        switch goal.type {
        case .weightTarget:
            return latestWeight <= goal.targetValue ? .completed : .active
        default:
            return currentValue(for: goal) >= goal.targetValue ? .completed : .active
        }
    }

    func progress(for challenge: Challenge) -> ChallengeProgress {
        let current = currentValue(for: challenge)
        let state: ChallengeState
        if current >= challenge.targetValue || challenge.completedAt != nil {
            state = .completed
        } else if calendar.startOfDay(for: Date()) > calendar.startOfDay(for: challenge.endDate) {
            state = .finished
        } else {
            state = .active
        }

        return ChallengeProgress(
            challenge: challenge,
            state: state,
            currentValue: current,
            targetValue: challenge.targetValue,
            unit: challenge.kind == .weightLoss ? challenge.unit : nil,
            detail: detailText(for: challenge, state: state)
        )
    }

    private var checkInsThisWeek: [DailyCheckIn] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return checkIns.filter { week.contains($0.date) }
    }

    private var checkInsThisMonth: [DailyCheckIn] {
        guard let month = calendar.dateInterval(of: .month, for: Date()) else { return [] }
        return checkIns.filter { month.contains($0.date) }
    }

    private var weightEntriesThisWeek: [WeightEntry] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return weightEntries.filter { week.contains($0.date) }
    }

    private var weightEntriesThisMonth: [WeightEntry] {
        guard let month = calendar.dateInterval(of: .month, for: Date()) else { return [] }
        return weightEntries.filter { month.contains($0.date) }
    }

    private var challengeProgressCards: [ChallengeProgress] {
        challenges
            .filter { $0.archivedAt == nil }
            .map(progress(for:))
    }

    private func currentValue(for challenge: Challenge) -> Double {
        switch challenge.kind {
        case .checkInDays:
            return Double(checkIns(in: challenge).count)
        case .weightLoss:
            guard let baseline = challenge.baselineWeight else { return 0 }
            let latest = latestWeightEntry(in: challenge)?.weight ?? baseline
            return max(baseline - latest, 0)
        }
    }

    private func checkIns(in challenge: Challenge) -> [DailyCheckIn] {
        let start = calendar.startOfDay(for: challenge.startDate)
        let end = calendar.startOfDay(for: challenge.endDate)
        return checkIns.filter {
            let day = calendar.startOfDay(for: $0.date)
            return day >= start && day <= end
        }
    }

    private func latestWeightEntry(in challenge: Challenge) -> WeightEntry? {
        let start = calendar.startOfDay(for: challenge.startDate)
        let end = min(calendar.startOfDay(for: Date()), calendar.startOfDay(for: challenge.endDate))
        return weightEntries
            .filter {
                let day = calendar.startOfDay(for: $0.date)
                return day >= start && day <= end
            }
            .sorted {
                if calendar.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.updatedAt < $1.updatedAt
                }
                return $0.date < $1.date
            }
            .last
    }

    private func detailText(for challenge: Challenge, state: ChallengeState) -> String {
        switch state {
        case .completed:
            return "Finished with care."
        case .finished:
            return "A focus window you showed up for."
        case .active:
            return dateRangeText(start: challenge.startDate, end: challenge.endDate)
        }
    }

    private func dateRangeText(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func filteredWeightEntries(for range: TrendRange) -> [WeightEntry] {
        guard let startDate = startDate(for: range) else { return weightEntries }
        return weightEntries.filter { $0.date >= startDate }
    }

    private func filteredMeasurementEntries(for range: TrendRange) -> [BodyMeasurementEntry] {
        guard let startDate = startDate(for: range) else { return measurementEntries }
        return measurementEntries.filter { $0.date >= startDate }
    }

    private func startDate(for range: TrendRange) -> Date? {
        let today = calendar.startOfDay(for: Date())
        switch range {
        case .sixWeeks:
            return calendar.date(byAdding: .day, value: -41, to: today)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: today)
        case .all:
            return nil
        }
    }

    private func checkIns(for period: GoalPeriod) -> [DailyCheckIn] {
        switch period {
        case .week:
            return checkInsThisWeek
        case .month:
            return checkInsThisMonth
        case .custom:
            return checkIns
        }
    }

    private func weightEntries(for period: GoalPeriod) -> [WeightEntry] {
        switch period {
        case .week:
            return weightEntriesThisWeek
        case .month:
            return weightEntriesThisMonth
        case .custom:
            return weightEntries
        }
    }

    private var sortedCheckIns: [DailyCheckIn] {
        checkIns.sorted { $0.date > $1.date }
    }

    private var latestWeightEntry: WeightEntry? {
        weightEntries
            .sorted {
                if calendar.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.updatedAt < $1.updatedAt
                }
                return $0.date < $1.date
            }
            .last
    }

    private var currentStreak: Int {
        streak(endingAt: currentStreakEndDate)
    }

    private var bestStreak: Int {
        let checkInsByDay = checkInsByStartDay
        guard
            let firstCheckInDay = checkInsByDay.keys.min(),
            let endDay = currentStreakEndDate
        else { return 0 }

        var best = 0
        var current = 0
        var cursor = firstCheckInDay

        while cursor <= endDay {
            switch streakEffect(on: cursor, checkInsByDay: checkInsByDay) {
            case .increment:
                current += 1
                best = max(best, current)
            case .pause:
                break
            case .breakStreak:
                current = 0
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }

        return best
    }

    private func streak(endingAt date: Date?) -> Int {
        guard let date else { return 0 }
        let checkInsByDay = checkInsByStartDay
        var cursor = calendar.startOfDay(for: date)
        var count = 0

        while true {
            switch streakEffect(on: cursor, checkInsByDay: checkInsByDay) {
            case .increment:
                count += 1
            case .pause:
                break
            case .breakStreak:
                return count
            }

            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return count }
            cursor = previous
        }
    }

    private var currentStreakEndDate: Date? {
        let today = calendar.startOfDay(for: Date())
        let checkInsByDay = checkInsByStartDay

        if checkInsByDay[today] != nil || profile.isPlannedFlexDay(today, calendar: calendar) {
            return today
        }

        return calendar.date(byAdding: .day, value: -1, to: today)
    }

    private enum StreakDayEffect {
        case increment
        case pause
        case breakStreak
    }

    private func streakEffect(on day: Date, checkInsByDay: [Date: DietStatus]) -> StreakDayEffect {
        if let status = checkInsByDay[calendar.startOfDay(for: day)] {
            switch status {
            case .yes:
                return .increment
            case .flex:
                return .pause
            case .mostly, .no:
                return .breakStreak
            }
        }

        return profile.isPlannedFlexDay(day, calendar: calendar) ? .pause : .breakStreak
    }

    private var checkInsByStartDay: [Date: DietStatus] {
        var result: [Date: DailyCheckIn] = [:]
        for checkIn in checkIns {
            let day = calendar.startOfDay(for: checkIn.date)
            if let existing = result[day], existing.updatedAt > checkIn.updatedAt {
                continue
            }
            result[day] = checkIn
        }
        return result.mapValues(\.dietStatus)
    }

    private func calendarStatus(for checkIn: DailyCheckIn) -> CalendarDayStatus {
        switch checkIn.dietStatus {
        case .yes: .onPlan
        case .mostly: .mostly
        case .no: .missed
        case .flex: .flex
        }
    }

    private func mode(for goal: Goal) -> GoalCardMode {
        let current = currentValue(for: goal)
        switch goal.type {
        case .dietDays, .movementDays, .weighIns:
            let label = goal.type == .dietDays && plannedFlexDaysThisWeek > 0 ? "\(plannedFlexDaysThisWeek) Flex Days planned this week" : nil
            return .count(current: Int(current), target: Int(goal.targetValue), label: label)
        case .weightTarget:
            return .weight(
                current: latestWeight,
                toGo: max(latestWeight - goal.targetValue, 0),
                goal: goal.targetValue,
                unit: profile.unit,
                progressValue: max(profile.startingWeight - latestWeight, 0),
                totalValue: max(profile.startingWeight - goal.targetValue, 0.1)
            )
        }
    }
}

enum AchievementEvaluator {
    static func unlockedKeys(using metrics: TrackerMetrics) -> Set<String> {
        var keys = Set<String>()

        if !metrics.checkIns.isEmpty {
            keys.insert("first_check_in")
        }
        if !metrics.weightEntries.isEmpty {
            keys.insert("first_weight_log")
        }

        let checkInWeekCounts = countsByWeek(metrics.checkIns.map(\.date))
        let yesWeekCounts = countsByWeek(metrics.checkIns.filter { $0.dietStatus == .yes }.map(\.date))
        let activeMonthCount = countsByMonth(metrics.checkIns.map(\.date)).values.filter { $0 >= 8 }.count

        if checkInWeekCounts.values.contains(where: { $0 >= 3 }) {
            keys.insert("steady_week")
        }
        if yesWeekCounts.values.contains(where: { $0 >= metrics.profile.weeklyDietTarget }) {
            keys.insert("on_plan_week")
        }
        if distinctWeeks(metrics.checkIns.filter(\.moved).map(\.date)).count >= 4 {
            keys.insert("movement_month")
        }
        if metrics.weightEntries.count >= 8 && distinctWeeks(metrics.weightEntries.map(\.date)).count >= 4 {
            keys.insert("trend_builder")
        }
        let measurementDates = metrics.measurementEntries
            .filter { $0.snapshot.hasAnyValue }
            .map(\.date)
        if measurementDates.count >= 3 && distinctMonths(measurementDates).count >= 2 {
            keys.insert("measurement_trend")
        }
        if activeMonthCount >= 3 {
            keys.insert("three_month_rhythm")
        }
        if activeMonthCount >= 6 {
            keys.insert("six_month_rhythm")
        }
        if activeMonthCount >= 12 {
            keys.insert("year_of_showing_up")
        }

        return keys
    }

    private static var calendar: Calendar {
        Calendar.current
    }

    private static func countsByWeek(_ dates: [Date]) -> [Date: Int] {
        countsByPeriod(dates, component: .weekOfYear)
    }

    private static func countsByMonth(_ dates: [Date]) -> [Date: Int] {
        countsByPeriod(dates, component: .month)
    }

    private static func distinctWeeks(_ dates: [Date]) -> Set<Date> {
        Set(dates.compactMap { periodStart(for: $0, component: .weekOfYear) })
    }

    private static func distinctMonths(_ dates: [Date]) -> Set<Date> {
        Set(dates.compactMap { periodStart(for: $0, component: .month) })
    }

    private static func countsByPeriod(_ dates: [Date], component: Calendar.Component) -> [Date: Int] {
        dates.reduce(into: [:]) { counts, date in
            guard let start = periodStart(for: date, component: component) else { return }
            counts[start, default: 0] += 1
        }
    }

    private static func periodStart(for date: Date, component: Calendar.Component) -> Date? {
        calendar.dateInterval(of: component, for: date).map(\.start)
    }
}

extension Goal {
    static func defaults(for profile: UserProfile) -> [Goal] {
        GoalType.allCases.map { coreGoal(for: $0, profile: profile) }
    }

    static func coreGoal(for type: GoalType, profile: UserProfile) -> Goal {
        Goal(
            type: type,
            title: coreTitle(for: type, profile: profile),
            targetValue: coreTargetValue(for: type, profile: profile),
            period: corePeriod(for: type),
            isCore: true
        )
    }

    static func coreTitle(for type: GoalType, profile: UserProfile) -> String {
        switch type {
        case .dietDays:
            "Follow diet \(profile.weeklyDietTarget) days this week"
        case .weightTarget:
            "Reach \(String(format: "%.1f", profile.goalWeight)) \(profile.unit)"
        case .movementDays:
            "Move your body \(profile.weeklyMovementTarget) days this week"
        case .weighIns:
            "Log weight \(profile.weeklyWeighInTarget) times this week"
        }
    }

    static func coreTargetValue(for type: GoalType, profile: UserProfile) -> Double {
        switch type {
        case .dietDays:
            Double(profile.weeklyDietTarget)
        case .weightTarget:
            profile.goalWeight
        case .movementDays:
            Double(profile.weeklyMovementTarget)
        case .weighIns:
            Double(profile.weeklyWeighInTarget)
        }
    }

    static func corePeriod(for type: GoalType) -> GoalPeriod {
        type == .weightTarget ? .custom : .week
    }
}

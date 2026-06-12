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

import Foundation
import UserNotifications

@MainActor
enum CheckInReminderScheduler {
    nonisolated private static let identifierPrefix = "checkInReminder-"
    nonisolated static let routeUserInfoKey = "route"
    nonisolated static let routeUserInfoValue = "checkInReminder"
    private static let notificationTitle = "Ready to wrap up today?"
    private static let notificationBody = "Take a quick moment for your check-in."

    nonisolated static func isCheckInReminderIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(identifierPrefix)
    }

    nonisolated static func isCheckInReminderResponse(_ response: UNNotificationResponse) -> Bool {
        let request = response.notification.request
        let route = request.content.userInfo[routeUserInfoKey] as? String
        return isCheckInReminderIdentifier(request.identifier) || route == routeUserInfoValue
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func refresh(profile: UserProfile, checkIns: [DailyCheckIn]) async {
        await cancelAll()

        guard profile.checkInReminderEnabled else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        let checkedDays = Set(
            checkIns.map { calendar.startOfDay(for: $0.date).timeIntervalSinceReferenceDate }
        )

        for dayOffset in 0..<30 {
            guard
                let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)),
                let fireDate = reminderDate(
                    on: day,
                    hour: profile.checkInReminderHour,
                    minute: profile.checkInReminderMinute
                )
            else { continue }

            guard fireDate > now else { continue }

            let dayKey = calendar.startOfDay(for: fireDate).timeIntervalSinceReferenceDate
            guard !checkedDays.contains(dayKey) else { continue }

            let content = UNMutableNotificationContent()
            content.title = notificationTitle
            content.body = notificationBody
            content.sound = .default
            content.userInfo = [Self.routeUserInfoKey: Self.routeUserInfoValue]

            let triggerComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: fireDate),
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter(Self.isCheckInReminderIdentifier)
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func reminderDate(on day: Date, hour: Int, minute: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    private static func identifier(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(identifierPrefix)\(formatter.string(from: date))"
    }
}

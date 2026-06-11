import Combine
import Foundation
import UserNotifications

@MainActor
final class CheckInNotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = CheckInNotificationRouter()

    @Published var pendingCheckInReminderRouteID: UUID?

    private override init() {
        super.init()
    }

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    @MainActor
    func consumeCheckInReminderRoute() {
        pendingCheckInReminderRouteID = nil
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard CheckInReminderScheduler.isCheckInReminderResponse(response) else {
            completionHandler()
            return
        }

        Task { @MainActor in
            Self.shared.pendingCheckInReminderRouteID = UUID()
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if CheckInReminderScheduler.isCheckInReminderIdentifier(notification.request.identifier) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([])
        }
    }
}

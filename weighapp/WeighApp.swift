import SwiftUI
import SwiftData

@main
struct WeighApp: App {
    @StateObject private var notificationRouter = CheckInNotificationRouter.shared

    init() {
        CheckInNotificationRouter.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationRouter)
        }
        .modelContainer(for: [UserProfile.self, DailyCheckIn.self, WeightEntry.self, BodyMeasurementEntry.self, Goal.self, Challenge.self, NutritionistConnection.self, MealPlanCache.self, EarnedAchievement.self])
    }
}

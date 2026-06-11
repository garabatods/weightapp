import SwiftUI
import SwiftData

@main
struct WeighApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserProfile.self, DailyCheckIn.self, WeightEntry.self, Goal.self])
    }
}

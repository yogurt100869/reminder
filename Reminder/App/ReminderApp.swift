import SwiftData
import SwiftUI

@main
struct ReminderApp: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: Alarm.self)
        } catch {
            fatalError("Unable to create data store: \(error)")
        }
    }()

    init() {
        AlarmScheduler.shared.configureForegroundPresentation()
    }

    var body: some Scene {
        WindowGroup {
            AlarmListView()
        }
        .modelContainer(container)
    }
}

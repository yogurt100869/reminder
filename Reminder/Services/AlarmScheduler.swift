import Foundation
import UserNotifications

enum AlarmSchedulerError: LocalizedError {
    case notificationsDenied

    var errorDescription: String? {
        switch self {
        case .notificationsDenied:
            return "通知权限未开启。请前往“设置”允许通知后再创建闹钟。"
        }
    }
}

final class AlarmScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AlarmScheduler()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configureForegroundPresentation() {
        center.delegate = self
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func ensureAuthorization() async throws {
        switch await authorizationStatus() {
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else {
                throw AlarmSchedulerError.notificationsDenied
            }
        case .denied:
            throw AlarmSchedulerError.notificationsDenied
        case .authorized, .provisional, .ephemeral:
            return
        @unknown default:
            throw AlarmSchedulerError.notificationsDenied
        }
    }

    func schedule(_ alarm: Alarm, calendar: Calendar = .current) async throws {
        guard AlarmDateValidator.isValid(alarm.fireDate) else {
            throw AlarmSchedulingError.dateIsNotInFuture
        }

        let content = UNMutableNotificationContent()
        content.title = "闹钟"
        content.body = alarm.title
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Self.dateComponents(for: alarm.fireDate, calendar: calendar),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancel(_ alarm: Alarm) {
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [alarm.id.uuidString])
    }

    static func dateComponents(for date: Date, calendar: Calendar) -> DateComponents {
        var components = calendar.dateComponents(
            [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
            from: date
        )
        components.nanosecond = nil
        return components
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

enum AlarmSchedulingError: LocalizedError {
    case dateIsNotInFuture

    var errorDescription: String? {
        switch self {
        case .dateIsNotInFuture:
            return "闹钟时间必须晚于当前时间。"
        }
    }
}

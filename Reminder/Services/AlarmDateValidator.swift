import Foundation

enum AlarmDateValidator {
    static func isValid(_ fireDate: Date, now: Date = .now) -> Bool {
        fireDate > now
    }
}

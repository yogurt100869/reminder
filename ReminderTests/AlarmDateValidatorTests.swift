import XCTest
@testable import Reminder

final class AlarmDateValidatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testFutureDateIsValid() {
        let now = date(2026, 9, 22, 14, 0)

        XCTAssertTrue(
            AlarmDateValidator.isValid(
                date(2026, 9, 29, 14, 0),
                now: now
            )
        )
    }

    func testCurrentAndPastDatesAreInvalid() {
        let now = date(2026, 9, 22, 14, 0)

        XCTAssertFalse(AlarmDateValidator.isValid(now, now: now))
        XCTAssertFalse(
            AlarmDateValidator.isValid(
                date(2026, 9, 22, 13, 59),
                now: now
            )
        )
    }

    func testNotificationComponentsPreserveSelectedTime() {
        let alarmDate = date(2026, 9, 29, 14, 5)

        let components = AlarmScheduler.dateComponents(
            for: alarmDate,
            calendar: calendar
        )

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 29)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 5)
        XCTAssertEqual(components.timeZone, calendar.timeZone)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}

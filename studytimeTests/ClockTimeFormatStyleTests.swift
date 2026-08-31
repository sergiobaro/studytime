import Foundation
import Testing
@testable import studytime

struct ClockTimeFormatStyleTests {

    @Test(arguments: [
        (0, "00:00"),
        (9, "00:09"),
        (59, "00:59"),
        (60, "01:00"),
        (1500, "25:00"),
        (3599, "59:59"),
    ])
    func belowAnHourItShowsPaddedMinutesAndSeconds(seconds: Int, expected: String) {
        #expect(seconds.formatted(.clockTime) == expected)
    }

    @Test(arguments: [
        (3600, "1:00:00"),
        (3661, "1:01:01"),
        (10_800, "3:00:00"),
        (86_399, "23:59:59"),
        (360_000, "100:00:00"),
    ])
    func atAnHourAndAboveItGainsAnHoursField(seconds: Int, expected: String) {
        #expect(seconds.formatted(.clockTime) == expected)
    }

    /// A timer should never render a negative clock.
    @Test(arguments: [-1, -60, Int.min])
    func negativeInputsClampToZero(seconds: Int) {
        #expect(seconds.formatted(.clockTime) == "00:00")
    }

    @Test func theStyleIsUsableDirectly() {
        #expect(ClockTimeFormatStyle().format(1500) == "25:00")
    }
}

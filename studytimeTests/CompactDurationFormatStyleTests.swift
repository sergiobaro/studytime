import Foundation
import Testing
@testable import studytime

struct CompactDurationFormatStyleTests {

    @Test func minutesOnly() {
        #expect(60.formatted(.compactDuration) == "1m")
        #expect((45 * 60).formatted(.compactDuration) == "45m")
        #expect(3_599.formatted(.compactDuration) == "59m")
    }

    @Test func wholeHoursDropTheMinutes() {
        #expect(3_600.formatted(.compactDuration) == "1h")
        #expect((4 * 3_600).formatted(.compactDuration) == "4h")
    }

    @Test func hoursAndMinutesTogether() {
        #expect((3_600 + 15 * 60).formatted(.compactDuration) == "1h 15m")
        #expect((2 * 3_600 + 5 * 60 + 30).formatted(.compactDuration) == "2h 5m")
    }

    /// Something was recorded, but not a whole minute of it — saying "0m"
    /// would read as a day with nothing on it.
    @Test func lessThanAMinuteIsNotRoundedAway() {
        #expect(1.formatted(.compactDuration) == "<1m")
        #expect(59.formatted(.compactDuration) == "<1m")
    }

    @Test func nothingIsZeroAndNegativesDoNotAppear() {
        #expect(0.formatted(.compactDuration) == "0m")
        #expect((-90).formatted(.compactDuration) == "0m")
    }
}

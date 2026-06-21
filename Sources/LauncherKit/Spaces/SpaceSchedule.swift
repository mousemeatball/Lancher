import Foundation

/// An optional schedule that makes a Space activate automatically on given weekdays from a start
/// time. `weekdays` uses `Calendar`'s 1=Sunday ... 7=Saturday convention.
public struct SpaceSchedule: Codable, Sendable, Hashable {
    public var weekdays: Set<Int>
    public var hour: Int
    public var minute: Int

    public init(weekdays: Set<Int>, hour: Int, minute: Int) {
        self.weekdays = weekdays
        self.hour = hour
        self.minute = minute
    }

    /// Minutes-since-midnight start time.
    public var startMinutes: Int { hour * 60 + minute }
}

import Foundation

/// Pure logic for schedule-based Space switching. Testable with an injected calendar/date.
public enum SpaceScheduler {
    /// The Space that should be active at `date`: among spaces scheduled for today's weekday whose
    /// start time has already passed, the one with the latest start time wins. Returns nil if none.
    public static func activeSpace(at date: Date, among spaces: [Space], calendar: Calendar = .current) -> Space? {
        let weekday = calendar.component(.weekday, from: date)
        let nowMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)

        let candidates: [(space: Space, start: Int)] = spaces.compactMap { space in
            guard let schedule = space.schedule,
                  schedule.weekdays.contains(weekday),
                  schedule.startMinutes <= nowMinutes
            else { return nil }
            return (space, schedule.startMinutes)
        }
        return candidates.max { $0.start < $1.start }?.space
    }
}

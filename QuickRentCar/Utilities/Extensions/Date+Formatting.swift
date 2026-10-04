import Foundation

extension Date {
    /// e.g. "Oct 15, 2026"
    var displayDate: String {
        self.formatted(date: .abbreviated, time: .omitted)
    }

    /// e.g. "10:30 AM"
    var displayTime: String {
        self.formatted(date: .omitted, time: .shortened)
    }

    /// e.g. "Oct 15, 2026 at 10:30 AM"
    var displayDateTime: String {
        self.formatted(date: .abbreviated, time: .shortened)
    }

    /// Number of full days between two dates
    func days(to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: endDate)
        return max(1, components.day ?? 1)
    }

    /// Returns true if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns a date at the start of the day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Adds given number of days
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

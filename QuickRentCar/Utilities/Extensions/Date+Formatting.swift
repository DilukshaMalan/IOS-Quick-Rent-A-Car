import Foundation

extension Date {
    var displayDate: String {
        self.formatted(date: .abbreviated, time: .omitted)
    }

    var displayTime: String {
        self.formatted(date: .omitted, time: .shortened)
    }

    var displayDateTime: String {
        self.formatted(date: .abbreviated, time: .shortened)
    }

    func days(to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: endDate)
        return max(1, components.day ?? 1)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct RentalEntry: TimelineEntry {
    let date: Date
    let vehicleName: String
    let status: String
    let returnDate: Date?
    let location: String
}

// MARK: - Timeline Provider
struct RentalStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> RentalEntry {
        RentalEntry(date: Date(), vehicleName: "Toyota Camry", status: "Active",
                    returnDate: Date().addingTimeInterval(86400 * 2), location: "Colombo")
    }

    func getSnapshot(in context: Context, completion: @escaping (RentalEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RentalEntry>) -> Void) {
        // Read shared data from App Groups
        let defaults = UserDefaults(suiteName: "group.com.quickrentcar.app")
        let vehicleName = defaults?.string(forKey: "activeVehicle") ?? "No Active Rental"
        let status = defaults?.string(forKey: "rentalStatus") ?? "—"
        let location = defaults?.string(forKey: "pickupLocation") ?? "—"
        let returnTimestamp = defaults?.double(forKey: "returnDate")
        let returnDate = returnTimestamp != nil ? Date(timeIntervalSince1970: returnTimestamp!) : nil

        let entry = RentalEntry(date: Date(), vehicleName: vehicleName, status: status,
                                returnDate: returnDate, location: location)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View
struct RentalStatusWidgetView: View {
    var entry: RentalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color(red: 0.0, green: 0.478, blue: 1.0))
                Text("QuickRentCar")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.0, green: 0.478, blue: 1.0))
            }

            Text(entry.vehicleName)
                .font(.headline)
                .lineLimit(1)

            if let returnDate = entry.returnDate {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: returnDate).day ?? 0
                Label("\(daysLeft)d remaining", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text(entry.location)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)

            Spacer()

            Text(entry.status)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(red: 0.0, green: 0.478, blue: 1.0))
                .clipShape(Capsule())
        }
        .padding()
        .containerBackground(.fill, for: .widget)
    }
}

// MARK: - Widget Configuration
struct QuickRentCarWidget: Widget {
    let kind: String = "QuickRentCarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RentalStatusProvider()) { entry in
            RentalStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Rental Status")
        .description("View your active rental at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle
@main
struct QuickRentCarWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickRentCarWidget()
    }
}

#Preview(as: .systemSmall) {
    QuickRentCarWidget()
} timeline: {
    RentalEntry(date: Date(), vehicleName: "Toyota Camry", status: "Active",
                returnDate: Date().addingTimeInterval(86400 * 2), location: "Colombo Fort")
}

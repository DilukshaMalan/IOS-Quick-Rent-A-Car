import SwiftUI

enum BookingAvailabilityState {
    case available
    case booked(DateRange)
    case unavailable
}

struct BookingAvailabilityBanner: View {
    let state: BookingAvailabilityState
    var isChecking = false

    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if isChecking {
                ProgressView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
    }

    private var tint: Color {
        switch state {
        case .available:             return .green
        case .booked, .unavailable:  return .orange
        }
    }

    private var icon: String {
        switch state {
        case .available:             return "checkmark.circle.fill"
        case .booked, .unavailable:  return "exclamationmark.triangle.fill"
        }
    }

    private var title: String {
        switch state {
        case .available:    return "Available for your dates"
        case .booked:       return "Not available for these dates"
        case .unavailable:  return "Vehicle unavailable"
        }
    }

    private var detail: String? {
        switch state {
        case .available:
            return nil
        case .booked(let period):
            return "Already booked \(period.start.displayDate) – \(period.end.displayDate). Try different dates."
        case .unavailable:
            return "This vehicle can't be booked right now."
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        BookingAvailabilityBanner(state: .available)
        BookingAvailabilityBanner(state: .booked(DateRange(start: Date(), end: Date().adding(days: 3))))
        BookingAvailabilityBanner(state: .unavailable, isChecking: true)
    }
    .padding()
}

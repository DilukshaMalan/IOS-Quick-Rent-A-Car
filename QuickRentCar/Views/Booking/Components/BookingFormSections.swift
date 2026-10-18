import SwiftUI

// MARK: - Section title
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.fallbackNavy)
    }
}

// MARK: - Location section
struct BookingLocationSection: View {
    @Binding var pickupLocation: String
    @Binding var dropOffLocation: String
    @State private var sameAsPickup = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionLabel("Location")

            LocationField(icon: "arrow.up.circle.fill", placeholder: "Pickup location", text: $pickupLocation)

            Toggle("Drop-off at the same location", isOn: $sameAsPickup)
                .font(.subheadline)
                .tint(Color.fallbackBlue)

            if !sameAsPickup {
                LocationField(icon: "arrow.down.circle.fill", placeholder: "Drop-off location", text: $dropOffLocation)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sameAsPickup)
        .onChange(of: sameAsPickup) { _, isOn in
            if isOn { dropOffLocation = pickupLocation }
        }
        .onChange(of: pickupLocation) { _, newValue in
            if sameAsPickup { dropOffLocation = newValue }
        }
    }
}

struct LocationField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Color.fallbackBlue)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
    }
}

// MARK: - Rental period section
struct BookingRentalPeriodSection: View {
    @Binding var pickupDate: Date
    @Binding var returnDate: Date
    let rentalDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionLabel("Rental Period")

            HStack(spacing: .spacingM) {
                DateSection(
                    label: "Pick Up",
                    date: $pickupDate,
                    range: Date().startOfDay...Date.distantFuture
                )
                DateSection(
                    label: "Return",
                    date: $returnDate,
                    range: pickupDate...Date.distantFuture
                )
            }

            Text("\(rentalDays) day\(rentalDays == 1 ? "" : "s") rental")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        // If the pick-up moves past the return date, push the return date forward
        .onChange(of: pickupDate) { _, newPickup in
            if returnDate <= newPickup {
                returnDate = newPickup.adding(days: 1)
            }
        }
    }
}

struct DateSection: View {
    let label: String
    @Binding var date: Date
    let range: ClosedRange<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            DatePicker("", selection: $date, in: range, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
        .padding()
        .cardStyle()
        .frame(maxWidth: .infinity)
    }
}

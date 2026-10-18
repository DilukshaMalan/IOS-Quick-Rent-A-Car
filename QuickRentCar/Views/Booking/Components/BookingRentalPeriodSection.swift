import SwiftUI

// MARK: - Rental period section
/// One summary card for the whole trip + quick duration chips.
/// Tapping the card opens a sheet with a calendar to change the dates and times.
struct BookingRentalPeriodSection: View {
    @Binding var pickupDate: Date
    @Binding var returnDate: Date
    let rentalDays: Int
    var unavailablePeriods: [DateRange] = []

    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionLabel("Rental Period")

            BookingDateRangeCard(
                pickupDate: pickupDate,
                returnDate: returnDate,
                rentalDays: rentalDays
            ) {
                showEditor = true
            }

            QuickDurationChips(pickupDate: pickupDate, returnDate: $returnDate)
        }
        // Moving the pick-up date keeps the rental length, instead of leaving the return date behind.
        .onChange(of: pickupDate) { oldValue, newValue in
            let shifted = returnDate.addingTimeInterval(newValue.timeIntervalSince(oldValue))
            returnDate = shifted > newValue ? shifted : newValue.adding(days: 1)
        }
        .sheet(isPresented: $showEditor) {
            DateRangeEditorSheet(
                pickupDate: $pickupDate,
                returnDate: $returnDate,
                rentalDays: rentalDays,
                unavailablePeriods: unavailablePeriods
            )
        }
    }
}

// MARK: - Summary card
struct BookingDateRangeCard: View {
    let pickupDate: Date
    let returnDate: Date
    let rentalDays: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: .spacingM) {
                HStack(alignment: .center) {
                    dateColumn(title: "PICK-UP", date: pickupDate, alignment: .leading)

                    Spacer(minLength: .spacingS)

                    VStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("\(rentalDays) day\(rentalDays == 1 ? "" : "s")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.fallbackBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.fallbackBlue.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: .spacingS)

                    dateColumn(title: "RETURN", date: returnDate, alignment: .trailing)
                }

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("Tap to change dates and times")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private func dateColumn(title: String, date: Date, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                .font(.subheadline.weight(.semibold))
            Text(date.displayTime)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Quick duration chips
struct QuickDurationChips: View {
    let pickupDate: Date
    @Binding var returnDate: Date

    private struct Option: Identifiable {
        let label: String
        let days: Int
        var id: Int { days }
    }

    private let options = [
        Option(label: "1 day", days: 1),
        Option(label: "3 days", days: 3),
        Option(label: "1 week", days: 7)
    ]

    var body: some View {
        HStack(spacing: .spacingS) {
            ForEach(options) { option in
                let target = pickupDate.adding(days: option.days)
                let isSelected = abs(target.timeIntervalSince(returnDate)) < 1

                Button {
                    returnDate = target
                } label: {
                    Text(option.label)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? Color.white : Color.fallbackBlue)
                        .background(isSelected ? Color.fallbackBlue : Color.fallbackBlue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Editor sheet
struct DateRangeEditorSheet: View {
    @Binding var pickupDate: Date
    @Binding var returnDate: Date
    let rentalDays: Int
    let unavailablePeriods: [DateRange]

    @Environment(\.dismiss) private var dismiss
    @State private var editing: Field = .pickup

    enum Field: CaseIterable, Identifiable {
        case pickup, dropoff
        var id: Self { self }
        var title: String { self == .pickup ? "Pick-up" : "Return" }
    }

    private var pickupRange: ClosedRange<Date> { Date().startOfDay...Date.distantFuture }
    private var returnRange: ClosedRange<Date> { pickupDate...Date.distantFuture }

    /// Upcoming bookings on this vehicle, so people can avoid them.
    private var upcomingBooked: [DateRange] {
        Array(
            unavailablePeriods
                .filter { $0.end > Date() }
                .sorted { $0.start < $1.start }
                .prefix(4)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingM) {
                    Picker("Editing", selection: $editing) {
                        ForEach(Field.allCases) { field in
                            Text(field.title).tag(field)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker(
                        "",
                        selection: editing == .pickup ? $pickupDate : $returnDate,
                        in: editing == .pickup ? pickupRange : returnRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    Text("\(pickupDate.displayDateTime) → \(returnDate.displayDateTime)  ·  \(rentalDays) day\(rentalDays == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if !upcomingBooked.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Already booked", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                            ForEach(upcomingBooked, id: \.self) { period in
                                Text("\(period.start.displayDate) – \(period.end.displayDate)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
                    }
                }
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingM)
            }
            .navigationTitle("Rental dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

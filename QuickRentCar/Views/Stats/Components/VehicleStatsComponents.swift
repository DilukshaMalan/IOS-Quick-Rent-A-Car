import SwiftUI

// MARK: - Vehicle number header
struct VehicleInfoHeader: View {
    let vehicleNumber: String
    let rentalId: String?

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundStyle(Color.fallbackBlue)
                .frame(width: 48, height: 48)
                .background(Color.fallbackBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Vehicle No.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vehicleNumber)
                    .font(.title3.bold())
                    .foregroundStyle(Color.fallbackNavy)
                if let rentalId {
                    Text("Rental \(rentalId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Custom date range
struct CustomRangeCard: View {
    @Binding var start: Date
    @Binding var end: Date
    let available: ClosedRange<Date>
    let timeZone: TimeZone

    // Clamped so the ranges can never be inverted (a reversed ClosedRange would crash).
    private var startRange: ClosedRange<Date> {
        let upper = min(max(end, available.lowerBound), available.upperBound)
        return available.lowerBound...upper
    }

    private var endRange: ClosedRange<Date> {
        let lower = max(min(start, available.upperBound), available.lowerBound)
        return lower...available.upperBound
    }

    var body: some View {
        VStack(spacing: .spacingS) {
            DatePicker("From", selection: $start, in: startRange, displayedComponents: .date)
            Divider()
            DatePicker("To", selection: $end, in: endRange, displayedComponents: .date)
        }
        .environment(\.timeZone, timeZone)
        .padding()
        .cardStyle()
    }
}

// MARK: - Tappable vehicle icon for maps
/// Shows a car icon. Tap it and the icon turns into an info card (vehicle number, current speed,
/// engine state); tap the card and it turns back into the car icon.
/// Selection lives in the parent so it survives live updates.
struct VehicleMapMarker: View {
    let vehicleNumber: String
    let speedKmh: Double?
    let engineOn: Bool?
    @Binding var isSelected: Bool
    var tint: Color = .red

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { isSelected.toggle() }
        } label: {
            if isSelected {
                VehicleInfoBubble(vehicleNumber: vehicleNumber, speedKmh: speedKmh, engineOn: engineOn)
                    .fixedSize()
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundStyle(tint)
                    .padding(8)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(radius: 3)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Vehicle \(vehicleNumber)")
        .accessibilityHint(isSelected
                           ? "Tap to show the vehicle icon again"
                           : "Tap to show the vehicle number and current speed")
    }
}

struct VehicleInfoBubble: View {
    let vehicleNumber: String
    let speedKmh: Double?
    let engineOn: Bool?

    private var speedText: String {
        guard let speedKmh else { return "-- km/h" }
        return String(format: "%.1f km/h", speedKmh)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(vehicleNumber, systemImage: "car.fill")
                .font(.caption.weight(.bold))

            Label(speedText, systemImage: "speedometer")
                .font(.caption)

            if let engineOn {
                HStack(spacing: 5) {
                    Circle()
                        .fill(engineOn ? Color.green : Color.gray)
                        .frame(width: 7, height: 7)
                    Text(engineOn ? "Engine on" : "Engine off")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 3)
    }
}

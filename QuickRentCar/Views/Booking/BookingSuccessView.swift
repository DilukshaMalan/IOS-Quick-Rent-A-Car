import SwiftUI

struct BookingSuccessView: View {
    let vehicleName: String
    let bookingId: String
    let pickupDate: Date
    let returnDate: Date
    let pickupLocation: String
    let totalPrice: Double

    @Environment(\.dismiss) private var dismiss
    @State private var animateIcon = false
    @State private var animateContent = false
    @State private var goHome = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.fallbackBlue.opacity(0.08), Color(.systemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacingXL) {
                    ZStack {
                        Circle()
                            .fill(Color.fallbackBlue.opacity(0.1))
                            .frame(width: 130, height: 130)
                            .scaleEffect(animateIcon ? 1.1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: animateIcon)

                        Circle()
                            .fill(Color.fallbackBlue.opacity(0.18))
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateIcon ? 1.0 : 0.7)
                            .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.15), value: animateIcon)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.fallbackBlue)
                            .symbolEffect(.bounce, value: animateIcon)
                    }
                    .padding(.top, .spacingXXL)

                    VStack(spacing: .spacingS) {
                        Text("Booking Confirmed!")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.fallbackNavy)

                        Text("Your \(vehicleName) is all set. Safe travels! 🚗")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 6) {
                            Image(systemName: "number.square.fill")
                                .foregroundStyle(Color.fallbackBlue)
                            Text(bookingId.prefix(8).uppercased())
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(Color.fallbackNavy)
                        }
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingXS + 2)
                        .background(Color.fallbackBlue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.45).delay(0.25), value: animateContent)

                    VStack(alignment: .leading, spacing: .spacingM) {
                        Label("Your Trip Details", systemImage: "list.clipboard.fill")
                            .font(.headline)
                            .foregroundStyle(Color.fallbackNavy)

                        Divider()

                        SuccessDetailRow(icon: "car.fill",
                                         label: "Vehicle",
                                         value: vehicleName)

                        SuccessDetailRow(icon: "mappin.circle.fill",
                                         label: "Pick-up Location",
                                         value: pickupLocation)

                        SuccessDetailRow(icon: "clock.fill",
                                         label: "Pick-up Date",
                                         value: pickupDate.displayDate)

                        SuccessDetailRow(icon: "clock.arrow.circlepath",
                                         label: "Return Date",
                                         value: returnDate.displayDate)

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Paid")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(PriceCalculator.format(totalPrice))
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.fallbackBlue)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                        }
                    }
                    .padding(.spacingL)
                    .cardStyle()
                    .padding(.horizontal, .spacingL)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateContent)

                    HStack(spacing: .spacingM) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(Color.fallbackBlue)
                            .font(.title3)
                        Text("You'll receive a reminder notification before your pick-up.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.spacingM)
                    .frame(maxWidth: .infinity)
                    .background(Color.fallbackBlue.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, .spacingL)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: animateContent)

                    VStack(spacing: .spacingS) {
                        NavigationLink(destination: HomeView()) {
                            Label("Go to Home", systemImage: "house.fill")
                                .primaryButtonStyle()
                        }
                        .padding(.horizontal, .spacingL)
                        
                        NavigationLink(destination: AllVehiclesView()) {
                            Label("Back to Browse", systemImage: "arrow.left")
                                .secondaryButtonStyle()
                        }
                        .padding(.horizontal, .spacingL)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.45).delay(0.5), value: animateContent)

                    Spacer(minLength: .spacingXXL)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            animateIcon = true
            animateContent = true
        }
    }
}

private struct SuccessDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.fallbackBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fallbackNavy)
            }
            Spacer()
        }
    }
}

private struct HomeDestination: View {
    var body: some View {
        EmptyView()
            .onAppear {
                NotificationCenter.default.post(name: .navigateToHome, object: nil)
            }
    }
}

extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
}

#Preview {
    NavigationStack {
        BookingSuccessView(
            vehicleName: "Toyota Camry",
            bookingId: "ABCD1234EFGH",
            pickupDate: Date().adding(days: 1),
            returnDate: Date().adding(days: 4),
            pickupLocation: "Colombo Branch",
            totalPrice: 462
        )
    }
}

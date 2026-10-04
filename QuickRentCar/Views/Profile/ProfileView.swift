import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showLicenseScan = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Header
                Section {
                    HStack(spacing: .spacingM) {
                        ZStack {
                            Circle()
                                .fill(Color.fallbackBlue.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundStyle(Color.fallbackBlue)
                        }

                        VStack(alignment: .leading, spacing: .spacingXS) {
                            Text(viewModel.user?.fullName ?? "—")
                                .font(.headline)
                            Text(viewModel.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, .spacingXS)
                }

                // MARK: - Account
                Section("Account") {
                    NavigationLink {
                        SettingsView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }

                    Button {
                        showLicenseScan = true
                    } label: {
                        Label("Driver License", systemImage: "creditcard.fill")
                            .foregroundStyle(Color.primary)
                    }

                    NavigationLink {
                        BookingHistoryView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Booking History", systemImage: "calendar.badge.clock")
                    }

                    NavigationLink {
                        PaymentRecordsView()
                            .environmentObject(authViewModel)
                    } label: {
                        Label("Payment Records", systemImage: "creditcard")
                    }
                }

                // MARK: - Security
                Section("Security") {
                    Toggle(isOn: $viewModel.isFaceIDEnabled) {
                        Label(BiometricAuthService.shared.biometricTypeName, systemImage: "faceid")
                    }
                    .onChange(of: viewModel.isFaceIDEnabled) {
                        viewModel.toggleFaceID()
                    }
                }

                // MARK: - Sign Out
                Section {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadProfile(userId: userId)
                }
            }
            .sheet(isPresented: $showLicenseScan) {
                LicenseScanView()
            }
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        List {
            Section("Notifications") {
                NavigationLink("Push Notifications") {
                    Text("Notification settings").padding()
                }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Booking History
struct BookingHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            if viewModel.bookings.isEmpty {
                ContentUnavailableView("No Bookings", systemImage: "calendar.badge.exclamationmark",
                    description: Text("Your booking history will appear here."))
            } else {
                ForEach(viewModel.bookings) { booking in
                    BookingRow(booking: booking)
                }
            }
        }
        .navigationTitle("Booking History")
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadProfile(userId: userId)
            }
        }
    }
}

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            HStack {
                Text(booking.vehicleName).font(.headline)
                Spacer()
                Label(booking.status.rawValue, systemImage: booking.status.icon)
                    .font(.caption)
                    .foregroundStyle(Color(booking.status.colorName))
            }

            Text("\(booking.pickupDate.displayDate) → \(booking.returnDate.displayDate)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(PriceCalculator.format(booking.totalPrice))
                .font(.subheadline.bold())
                .foregroundStyle(Color.fallbackBlue)
        }
        .padding(.vertical, .spacingXS)
    }
}

// MARK: - Payment Records
struct PaymentRecordsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            if viewModel.payments.isEmpty {
                ContentUnavailableView("No Payments", systemImage: "creditcard.trianglebadge.exclamationmark",
                    description: Text("Your payment history will appear here."))
            } else {
                ForEach(viewModel.payments) { payment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(payment.vehicleName).font(.headline)
                            Text(payment.formattedDate).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(payment.formattedAmount).font(.headline).foregroundStyle(Color.fallbackBlue)
                    }
                }
            }
        }
        .navigationTitle("Payments")
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.loadProfile(userId: userId)
            }
        }
    }
}

#Preview {
    ProfileView().environmentObject(AuthViewModel())
}

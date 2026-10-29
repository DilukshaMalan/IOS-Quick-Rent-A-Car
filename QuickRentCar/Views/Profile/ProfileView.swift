import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showLicenseScan = false

    var body: some View {
        NavigationStack {
            List {
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

                Section("Security") {
                    Toggle(isOn: $viewModel.isFaceIDEnabled) {
                        Label(BiometricAuthService.shared.biometricTypeName, systemImage: "faceid")
                    }
                    .onChange(of: viewModel.isFaceIDEnabled) {
                        viewModel.toggleFaceID()
                    }
                }

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

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @AppStorage("appColorScheme") private var appColorScheme: String = ""

    private enum AppearanceOption: String, CaseIterable, Identifiable {
        case system = ""
        case light  = "light"
        case dark   = "dark"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: return "System Default"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light:  return "sun.max.fill"
            case .dark:   return "moon.fill"
            }
        }
    }

    var body: some View {
        List {
            Section("Appearance") {
                ForEach(AppearanceOption.allCases) { option in
                    Button {
                        appColorScheme = option.rawValue
                    } label: {
                        HStack {
                            Label(option.label, systemImage: option.icon)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if appColorScheme == option.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.fallbackBlue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }

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

struct BookingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Booking History")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.fallbackNavy)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingM)

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
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
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

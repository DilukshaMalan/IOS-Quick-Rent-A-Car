import SwiftUI
import MapKit

struct VehicleStatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VehicleStatsViewModel()
    @State private var showVehicleInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {

                    // MARK: - Vehicle number
                    if let vehicleNumber = viewModel.vehicleId {
                        VehicleInfoHeader(vehicleNumber: vehicleNumber, rentalId: viewModel.rentalId)
                            .padding(.horizontal)
                    }

                    // MARK: - Map Preview
                    mapSection

                    // MARK: - Period Selector
                    VStack(spacing: .spacingS) {
                        Picker("Period", selection: $viewModel.selectedPeriod) {
                            ForEach(VehicleStatsViewModel.Period.allCases, id: \.self) { period in
                                Text(period.shortTitle).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)

                        Label(viewModel.periodDescription, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // MARK: - Custom range
                    if viewModel.selectedPeriod == .custom,
                       let available = viewModel.availableDateRange {
                        CustomRangeCard(
                            start: $viewModel.customStart,
                            end: $viewModel.customEnd,
                            available: available,
                            timeZone: VehicleStatsViewModel.displayTimeZone
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Summary Cards
                    TotalDistanceCard(totalKm: viewModel.periodStats.distanceKm,
                                      usedKm: viewModel.usedKm,
                                      includedKm: Int(viewModel.packageAllowanceKm))
                        .padding(.horizontal)

                    SpeedAnalyticsView(averageSpeed: viewModel.periodStats.averageSpeedKmh,
                                       maxSpeed: viewModel.periodStats.maxSpeedKmh)
                        .padding(.horizontal)

                    // MARK: - Journey Replay Navigation
                    NavigationLink(destination: JourneyReplayView(viewModel: viewModel)) {
                        VStack(spacing: 2) {
                            Text("Journey Replay")
                                .font(.headline)
                            Text(viewModel.replayPoints.isEmpty
                                 ? "No journeys in this period"
                                 : "\(viewModel.periodDescription) · \(viewModel.replayTrips.count) trip\(viewModel.replayTrips.count == 1 ? "" : "s")")
                                .font(.caption)
                                .opacity(0.85)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.fallbackBlue)
                        .foregroundColor(.white)
                        .cornerRadius(.cornerRadiusM)
                    }
                    .disabled(viewModel.replayPoints.isEmpty)
                    .opacity(viewModel.replayPoints.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Driving Stats")
            .task {
                await viewModel.loadTelemetry()
            }
        }
    }

    // MARK: - Map
    @ViewBuilder
    private var mapSection: some View {
        if let location = viewModel.lastKnownLocation {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)

            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )) {
                Annotation("", coordinate: coordinate) {
                    VehicleMapMarker(
                        vehicleNumber: viewModel.vehicleId ?? "Vehicle",
                        speedKmh: viewModel.lastKnownPoint?.speedKmh,
                        engineOn: viewModel.lastKnownPoint?.engineOn,
                        isSelected: $showVehicleInfo
                    )
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
            .padding(.horizontal)
        } else if viewModel.isLoading {
            ProgressView("Loading telemetry...")
                .frame(height: 200)
        } else {
            ContentUnavailableView(viewModel.errorMessage ?? "No location", systemImage: "location.slash")
                .frame(height: 200)
        }
    }
}

// MARK: - Total Distance Card (re-used from old StatsView)
struct TotalDistanceCard: View {
    let totalKm: Double
    let usedKm: Double
    let includedKm: Int

    var body: some View {
        VStack(spacing: .spacingM) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Distance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f km", totalKm))
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.fallbackNavy)
                }
                Spacer()
                Image(systemName: "road.lanes.curved.left")
                    .font(.title)
                    .foregroundStyle(Color.fallbackBlue)
            }
            if includedKm > 0 {
                VStack(spacing: .spacingXS) {
                    HStack {
                        Text("Mileage used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(usedKm)) / \(includedKm) km")
                            .font(.caption.bold())
                    }
                    ProgressView(value: usedKm, total: Double(includedKm))
                        .tint(usedKm / Double(includedKm) > 0.85 ? .orange : Color.fallbackBlue)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Speed Analytics (re-used)
struct SpeedAnalyticsView: View {
    let averageSpeed: Double
    let maxSpeed: Double

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Speed Analytics")
                .font(.headline)
                .foregroundStyle(Color.fallbackNavy)
            HStack(spacing: .spacingM) {
                SpeedStat(label: "Average Speed", value: averageSpeed, icon: "speedometer", color: Color.fallbackBlue)
                SpeedStat(label: "Max Speed", value: maxSpeed, icon: "bolt.fill", color: .orange)
            }
        }
        .padding()
        .cardStyle()
    }
}

struct SpeedStat: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacingS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(String(format: "%.1f", value))
                .font(.title2.bold())
                .foregroundStyle(Color.fallbackNavy)
            + Text(" km/h")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
    }
}

#Preview {
    VehicleStatsView()
        .environmentObject(AuthViewModel())
}

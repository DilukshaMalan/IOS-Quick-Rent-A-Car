import SwiftUI
import MapKit

struct VehicleStatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VehicleStatsViewModel()
    @State private var region = MKCoordinateRegion()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    
                    // MARK: - Map Preview
                    if let location = viewModel.lastKnownLocation {
                        Map(coordinateRegion: $region,
                            interactionModes: .all,
                            showsUserLocation: false,
                            userTrackingMode: .none,
                            annotationItems: [location]) { loc in
                            MapMarker(coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), tint: .blue)
                        }
                        .frame(height: 200)
                        .cornerRadius(.cornerRadiusM)
                        .onAppear {
                            region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        }
                    } else {
                        ContentUnavailableView("No location", systemImage: "location.slash")
                            .frame(height: 200)
                    }
                    
                    // MARK: - Period Selector
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(VehicleStatsViewModel.Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // MARK: - Summary Cards
                    TotalDistanceCard(totalKm: viewModel.packageAllowanceKm,
                                      usedKm: viewModel.usedKm,
                                      includedKm: Int(viewModel.packageAllowanceKm))
                        .padding(.horizontal)
                    
                    SpeedAnalyticsView(averageSpeed: viewModel.periodStats.averageSpeedKmh,
                                        maxSpeed: viewModel.periodStats.maxSpeedKmh)
                        .padding(.horizontal)
                    
                    // MARK: - Journey Replay Navigation
                    NavigationLink(destination: JourneyReplayView()) {
                        Text("Journey Replay")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.fallbackBlue)
                            .foregroundColor(.white)
                            .cornerRadius(.cornerRadiusM)
                    }
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
}

// MARK: - Total Distance Card (re‑used from old StatsView)
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

// MARK: - Speed Analytics (re‑used)
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

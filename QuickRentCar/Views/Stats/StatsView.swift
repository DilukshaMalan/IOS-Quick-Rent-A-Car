import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // MARK: - Period Selector
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(DailyDistance.StatPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // MARK: - Total Distance Card
                    TotalDistanceCard(
                        totalKm: viewModel.totalDistance,
                        usedKm: viewModel.usedMileage,
                        includedKm: viewModel.includedMileage
                    )
                    .padding(.horizontal)

                    // MARK: - Distance Chart
                    DistanceChartView(data: viewModel.chartData, period: viewModel.selectedPeriod)
                        .frame(height: 220)
                        .padding(.horizontal)

                    // MARK: - Speed Analytics
                    SpeedAnalyticsView(
                        averageSpeed: viewModel.averageSpeed,
                        maxSpeed: viewModel.maxSpeed
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Driving Stats")
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadStats(userId: userId)
                } else {
                    // No signed-in user (previews / before sign-in) — show sample data
                    await viewModel.loadSampleStats()
                }
            }
        }
    }
}

// MARK: - Total Distance Card
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

// MARK: - Distance Chart
struct DistanceChartView: View {
    let data: [DailyDistance]
    let period: DailyDistance.StatPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("\(period.rawValue) Distance")
                .font(.headline)
                .foregroundStyle(Color.fallbackNavy)

            if data.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.bar")
                    .frame(height: 150)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Distance (km)", item.distanceKm)
                    )
                    .foregroundStyle(Color.fallbackBlue.gradient)
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Speed Analytics
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
            +
            Text(" km/h")
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
    StatsView()
        .environmentObject(AuthViewModel())
}

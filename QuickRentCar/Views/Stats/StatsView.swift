import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(DailyDistance.StatPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    TotalDistanceCard(
                        totalKm: viewModel.totalDistance,
                        usedKm: viewModel.usedMileage,
                        includedKm: viewModel.includedMileage
                    )
                    .padding(.horizontal)

                    DistanceChartView(data: viewModel.chartData, period: viewModel.selectedPeriod)
                        .frame(height: 220)
                        .padding(.horizontal)

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
                    await viewModel.loadSampleStats()
                }
            }
        }
    }
}

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

#Preview {
    StatsView()
        .environmentObject(AuthViewModel())
}

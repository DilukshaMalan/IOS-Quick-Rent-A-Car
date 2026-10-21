
import SwiftUI
import MapKit

struct JourneyReplayView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VehicleStatsViewModel()

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 6.9271,
                longitude: 79.8612
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.02,
                longitudeDelta: 0.02
            )
        )
    )

    @State private var isPlaying = false
    @State private var playbackIndex = 0
    @State private var playbackSpeed: Double = 1.0
    @State private var timer: Timer?

    // MARK: - Telemetry Points

    private var allPoints: [TelemetryPoint] {
        viewModel.telemetry?.trips
            .sorted { $0.startTime < $1.startTime }
            .flatMap { $0.points.sorted { $0.timestamp < $1.timestamp } }
            ?? []
    }

    private var safePlaybackIndex: Int {
        guard !allPoints.isEmpty else { return 0 }
        return min(max(playbackIndex, 0), allPoints.count - 1)
    }

    private var currentPoint: TelemetryPoint? {
        guard !allPoints.isEmpty else { return nil }
        return allPoints[safePlaybackIndex]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // MARK: Map

                if viewModel.telemetry != nil {
                    Map(position: $cameraPosition) {

                        // Draw each trip separately to avoid connecting
                        // unrelated journeys with artificial lines.
                        ForEach(
                            Array(
                                (viewModel.telemetry?.trips ?? [])
                                    .sorted { $0.startTime < $1.startTime }
                                    .enumerated()
                            ),
                            id: \.offset
                        ) { _, trip in
                            if trip.points.count >= 2 {
                                MapPolyline(
                                    coordinates: trip.points
                                        .sorted {
                                            $0.timestamp < $1.timestamp
                                        }
                                        .map {
                                            CLLocationCoordinate2D(
                                                latitude: $0.latitude,
                                                longitude: $0.longitude
                                            )
                                        }
                                )
                                .stroke(
                                    Color.fallbackBlue,
                                    lineWidth: 4
                                )
                            }
                        }

                        // Start and end markers for the selected
                        // playback position's trip.
                        if let point = currentPoint {
                            Annotation(
                                "Rental Vehicle",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: point.latitude,
                                    longitude: point.longitude
                                )
                            ) {
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                    .padding(8)
                                    .background(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                    .frame(height: 300)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: .cornerRadiusM
                        )
                    )
                } else {
                    ContentUnavailableView(
                        "No telemetry data",
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(height: 300)
                }

                // MARK: Current Position

                if let point = currentPoint {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Journey Replay")
                            .font(.headline)

                        Text(
                            point.timestamp.formatted(
                                date: .abbreviated,
                                time: .standard
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        HStack {
                            Label(
                                String(
                                    format: "%.1f km/h",
                                    point.speedKmh ?? 0.0
                                ),
                                systemImage: "speedometer"
                            )

                            Spacer()

                            Text(
                                "Point \(safePlaybackIndex + 1) of \(allPoints.count)"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // MARK: Playback Controls

                HStack(spacing: 32) {
                    Button(action: resetPlayback) {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Restart journey")

                    Button(action: togglePlay) {
                        Image(
                            systemName: isPlaying
                                ? "pause.fill"
                                : "play.fill"
                        )
                        .font(.title)
                    }
                    .accessibilityLabel(
                        isPlaying ? "Pause replay" : "Play replay"
                    )
                    .disabled(allPoints.isEmpty)

                    Button(action: increaseSpeed) {
                        Image(systemName: "speedometer")
                            .font(.title2)
                    }
                    .accessibilityLabel("Change playback speed")
                    .disabled(allPoints.isEmpty)

                    Text(String(format: "%.1fx", playbackSpeed))
                        .font(.subheadline.monospacedDigit())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                // MARK: Timeline Slider

                if allPoints.count > 1 {
                    VStack(spacing: 4) {
                        Slider(
                            value: playbackIndexBinding,
                            in: 0...Double(allPoints.count - 1),
                            step: 1
                        ) {
                            Text("Journey progress")
                        }
                        .onChange(of: playbackIndex) { _, _ in
                            // Keep the car visible when scrubbing.
                            if let point = currentPoint {
                                moveCamera(to: point)
                            }
                        }

                        HStack {
                            Text("Start")
                            Spacer()
                            Text(
                                "\(Int(Double(safePlaybackIndex) / Double(allPoints.count - 1) * 100))%"
                            )
                            Spacer()
                            Text("End")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical)
            .navigationTitle("Journey Replay")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadTelemetry()
                setupInitialCamera()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: - Slider Binding

    private var playbackIndexBinding: Binding<Double> {
        Binding(
            get: {
                Double(safePlaybackIndex)
            },
            set: { newValue in
                playbackIndex = Int(newValue)
            }
        )
    }

    // MARK: - Camera

    private func setupInitialCamera() {
        guard let first = allPoints.first else { return }
        moveCamera(to: first)
    }

    private func moveCamera(to point: TelemetryPoint) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: point.latitude,
                    longitude: point.longitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: 0.02,
                    longitudeDelta: 0.02
                )
            )
        )
    }

    // MARK: - Playback

    private func togglePlay() {
        guard !allPoints.isEmpty else { return }

        if isPlaying {
            stopTimer()
        } else {
            // Start again from the beginning if replay has finished.
            if safePlaybackIndex >= allPoints.count - 1 {
                playbackIndex = 0
            }

            isPlaying = true
            startTimer()
        }
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5 / playbackSpeed,
            repeats: true
        ) { _ in
            advancePlayback()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    private func advancePlayback() {
        guard !allPoints.isEmpty else {
            stopTimer()
            return
        }

        if safePlaybackIndex < allPoints.count - 1 {
            playbackIndex = safePlaybackIndex + 1
        } else {
            stopTimer()
        }
    }

    private func resetPlayback() {
        stopTimer()
        playbackIndex = 0

        if let first = allPoints.first {
            moveCamera(to: first)
        }
    }

    private func increaseSpeed() {
        switch playbackSpeed {
        case 1.0:
            playbackSpeed = 2.0
        case 2.0:
            playbackSpeed = 4.0
        default:
            playbackSpeed = 1.0
        }

        if isPlaying {
            startTimer()
        }
    }
}

#Preview {
    JourneyReplayView()
        .environmentObject(AuthViewModel())
}

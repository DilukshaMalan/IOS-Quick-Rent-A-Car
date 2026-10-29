import Foundation
import CoreLocation

struct TelemetryStats {
    var totalDistanceKm: Double = 0
    var maxSpeedKmh: Double = 0
    var averageSpeedKmh: Double = 0
    var drivingTimeSec: Double = 0
    var tripCount: Int = 0
}

final class VehicleTelemetryService {
    static let shared = VehicleTelemetryService()
    private init() {}
    
    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
    
    private func distance(for points: [TelemetryPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<points.count {
            let p1 = points[i-1]
            let p2 = points[i]
            total += haversine(lat1: p1.latitude, lon1: p1.longitude,
                               lat2: p2.latitude, lon2: p2.longitude)
        }
        return total
    }
    
    private func filteredPoints(in interval: DateInterval, from points: [TelemetryPoint]) -> [TelemetryPoint] {
        points.filter { interval.contains($0.timestamp) }
    }
    
    func calculateStats(for interval: DateInterval, telemetry: VehicleTelemetry) -> TelemetryStats {
        var allPoints: [TelemetryPoint] = []
        var tripCount = 0
        var maxSpeed: Double = 0
        var totalDrivingTime: Double = 0
        
        for trip in telemetry.trips {
            let tripInterval = DateInterval(start: trip.startTime, end: trip.endTime)
            if interval.intersects(tripInterval) {
                let points = filteredPoints(in: interval, from: trip.points)
                if !points.isEmpty {
                    allPoints.append(contentsOf: points)
                    tripCount += 1
                    if let first = points.first, let last = points.last {
                        totalDrivingTime += last.timestamp.timeIntervalSince(first.timestamp)
                    }
                    for pt in points {
                        if let sp = pt.speedKmh, sp > maxSpeed {
                            maxSpeed = sp
                        }
                    }
                }
            }
        }
        let totalDist = distance(for: allPoints)
        let avgSpeed = totalDrivingTime > 0 ? (totalDist / (totalDrivingTime/3600.0)) : 0
        return TelemetryStats(totalDistanceKm: totalDist,
                              maxSpeedKmh: maxSpeed,
                              averageSpeedKmh: avgSpeed,
                              drivingTimeSec: totalDrivingTime,
                              tripCount: tripCount)
    }
    
    func rentalPackageUsage(telemetry: VehicleTelemetry) -> (usedKm: Double, remainingKm: Double, percentUsed: Double) {
        let totalDist = distance(for: telemetry.trips.flatMap { $0.points })
        let remaining = max(0, telemetry.packageAllowanceKm - totalDist)
        let percent = telemetry.packageAllowanceKm > 0 ? (totalDist / telemetry.packageAllowanceKm) * 100 : 0
        return (usedKm: totalDist, remainingKm: remaining, percentUsed: percent)
    }
}

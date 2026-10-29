import Foundation
import MapKit
import CoreLocation

// MARK: - Route model
/// A driving route that follows the roads, as a list of coordinates (not a straight line).
struct DrivingRoute {
    enum Source: String {
        case appleMaps = "Apple Maps"
        case osrm = "OpenStreetMap (OSRM)"
    }

    let coordinates: [CLLocationCoordinate2D]
    let distance: CLLocationDistance      // metres along the road
    let duration: TimeInterval            // seconds
    let source: Source

    /// Map rectangle that contains the whole route (used to zoom the map).
    var boundingMapRect: MKMapRect {
        coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            return rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
    }
}

enum RouteError: LocalizedError {
    case noRoute(String)
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .noRoute(let message), .badResponse(let message): return message
        }
    }
}

// MARK: - Provider protocol
/// A source of road routes. Add another one (Google, Mapbox, ...) by conforming to this
/// protocol and adding it to `RoadRouteService.providers`.
protocol RouteProvider {
    var name: String { get }
    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> DrivingRoute
}

// MARK: - Apple Maps (MKDirections)
/// Best quality where Apple has routing data. It has no driving directions for some countries
/// (Sri Lanka included), in which case it throws and the next provider is tried.
struct AppleMapsRouteProvider: RouteProvider {
    let name = "Apple Maps"

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> DrivingRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let response = try await MKDirections(request: request).calculate()
        guard let best = response.routes.first else {
            throw RouteError.noRoute("Apple Maps returned no route.")
        }
        return DrivingRoute(
            coordinates: best.polyline.coordinateArray,
            distance: best.distance,
            duration: best.expectedTravelTime,
            source: .appleMaps
        )
    }
}

// MARK: - OpenStreetMap (OSRM)
/// Free road routing on OpenStreetMap data, no API key. The public demo server is meant for
/// testing: for production use your own OSRM server or a paid routing API (Google, Mapbox, ...).
struct OSRMRouteProvider: RouteProvider {
    let name = "OpenStreetMap (OSRM)"
    var baseURL = "https://router.project-osrm.org"

    // OSRM response (only the parts we use). Coordinates are [longitude, latitude].
    private struct Response: Decodable {
        let code: String
        let message: String?
        let routes: [Route]?
    }
    private struct Route: Decodable {
        let distance: Double
        let duration: Double
        let geometry: Geometry
    }
    private struct Geometry: Decodable {
        let coordinates: [[Double]]
    }

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> DrivingRoute {
        // OSRM expects longitude,latitude order.
        let urlString = "\(baseURL)/route/v1/driving/"
            + "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)"
            + "?overview=full&geometries=geojson&steps=false"
        guard let url = URL(string: urlString) else {
            throw RouteError.badResponse("Invalid routing URL.")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("QuickRentCar-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw RouteError.badResponse("Routing server returned HTTP \(http.statusCode).")
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.code == "Ok", let route = decoded.routes?.first else {
            throw RouteError.noRoute(decoded.message ?? "No road route found (\(decoded.code)).")
        }

        var coordinates = route.geometry.coordinates.compactMap { pair -> CLLocationCoordinate2D? in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
        guard coordinates.count >= 2 else {
            throw RouteError.noRoute("The route had no geometry.")
        }

        // OSRM snaps both ends to the nearest road. Connect the real start / end points so the
        // line does not stop short of the airport marker or the vehicle.
        if let first = coordinates.first, Self.meters(first, origin) > 25 {
            coordinates.insert(origin, at: 0)
        }
        if let last = coordinates.last, Self.meters(last, destination) > 25 {
            coordinates.append(destination)
        }

        return DrivingRoute(
            coordinates: coordinates,
            distance: route.distance,
            duration: route.duration,
            source: .osrm
        )
    }

    private static func meters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}

// MARK: - Service
struct RouteOutcome {
    let route: DrivingRoute?
    /// One line per provider that failed, e.g. "Apple Maps: Directions Not Available".
    let problems: [String]
}

final class RoadRouteService {
    static let shared = RoadRouteService()

    /// Tried in order; the first one that returns a route wins.
    /// Apple Maps has no driving routes in Sri Lanka, so you can put `OSRMRouteProvider()` first
    /// to skip that failed request.
    var providers: [RouteProvider] = [
        AppleMapsRouteProvider(),
        OSRMRouteProvider()
    ]

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> RouteOutcome {
        var problems: [String] = []

        for provider in providers {
            if Task.isCancelled { break }
            do {
                let route = try await provider.route(from: origin, to: destination)
                #if DEBUG
                print("🧭 [Route] \(provider.name): \(route.coordinates.count) points, \(Int(route.distance)) m, \(Int(route.duration)) s")
                #endif
                return RouteOutcome(route: route, problems: problems)
            } catch {
                problems.append("\(provider.name): \(error.localizedDescription)")
                #if DEBUG
                print("🧭 [Route] \(provider.name) failed: \(error)")
                #endif
            }
        }
        return RouteOutcome(route: nil, problems: problems)
    }
}

// MARK: - Helpers
private extension MKPolyline {
    /// The polyline's points as plain coordinates.
    var coordinateArray: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}

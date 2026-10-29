import Foundation

struct GPSAPIHealthResponse: Decodable {
    let status: String
    let vehicles: Int
}

struct GPSAPIVehiclesResponse: Decodable {
    let vehicles: [GPSAPIVehicleSummary]
}

struct GPSAPIVehicleSummary: Decodable {
    let vehicleId: String
    let dataStart: Date
    let dataEnd: Date
    let tripCount: Int
    let pointCount: Int
    let lastKnown: GPSAPIPoint
}

struct GPSAPIPosition: Decodable {
    let vehicleId: String
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speedKmh: Double?
    let engineOn: Bool
}

struct GPSAPIPoint: Decodable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speedKmh: Double?
    let engineOn: Bool
}

struct GPSAPITrip: Decodable, Identifiable {
    var id: String { tripId }

    let tripId: String
    let startTime: Date
    let endTime: Date
    let startReason: String
    let endReason: String?
    let distanceKm: Double
    let maxSpeedKmh: Double
    let averageSpeedKmh: Double
    let points: [GPSAPIPoint]?
}

struct GPSAPITripsMeta: Decodable {
    let dataSource: String
    let samplingIntervalSeconds: Int
    let tripCount: Int
    let pointCount: Int?
    let effectiveIntervalSeconds: Int?
}

struct GPSAPITripsResponse: Decodable {
    let vehicleId: String
    let meta: GPSAPITripsMeta
    let trips: [GPSAPITrip]
}

private struct GPSAPIErrorEnvelope: Decodable {
    let error: GPSAPIErrorDetails
}

private struct GPSAPIErrorDetails: Decodable {
    let code: String
    let message: String
}

enum GPSAPIClientError: LocalizedError {
    case invalidURL
    case missingAPIKey
    case invalidResponse
    case server(
        statusCode: Int,
        code: String?,
        message: String?
    )

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The GPS API URL is invalid."

        case .missingAPIKey:
            return """
            GPS_API_KEY is missing. Configure it in the app's \
            Info.plist using the instructions provided.
            """

        case .invalidResponse:
            return "The GPS API returned an invalid response."

        case let .server(statusCode, code, message):
            let serverMessage = message ?? "The request failed."
            let errorCode = code.map { " [\($0)]" } ?? ""

            return "\(serverMessage)\(errorCode) (HTTP \(statusCode))"
        }
    }
}

final class TelemetryAPIClient {

    static let shared = TelemetryAPIClient()

    private let baseURL: URL
    private let apiKey: String?
    private let session: URLSession

    init(
        baseURL: URL = URL(
            string: "https://gps-api-2-production.up.railway.app"
        )!,
        apiKey: String? = Bundle.main.object(
            forInfoDictionaryKey: "GPS_API_KEY"
        ) as? String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    func fetchHealth() async throws -> GPSAPIHealthResponse {
        try await get(
            GPSAPIHealthResponse.self,
            path: "/api/v1/health",
            requiresAPIKey: false
        )
    }

    func fetchVehicles() async throws -> [GPSAPIVehicleSummary] {
        let response = try await get(
            GPSAPIVehiclesResponse.self,
            path: "/api/v1/vehicles"
        )

        return response.vehicles
    }

    func fetchPosition(
        vehicleId: String
    ) async throws -> GPSAPIPosition {
        try await get(
            GPSAPIPosition.self,
            path: "/api/v1/vehicles/\(vehicleId)/position"
        )
    }

    func fetchTrips(
        vehicleId: String,
        from: Date,
        to: Date,
        includePoints: Bool = false,
        maxPoints: Int = 5000
    ) async throws -> GPSAPITripsResponse {

        var queryItems = [
            URLQueryItem(
                name: "from",
                value: Self.apiTimestamp(from)
            ),
            URLQueryItem(
                name: "to",
                value: Self.apiTimestamp(to)
            )
        ]

        if includePoints {
            queryItems.append(
                URLQueryItem(
                    name: "includePoints",
                    value: "true"
                )
            )

            queryItems.append(
                URLQueryItem(
                    name: "maxPoints",
                    value: String(maxPoints)
                )
            )
        }

        return try await get(
            GPSAPITripsResponse.self,
            path: "/api/v1/vehicles/\(vehicleId)/trips",
            queryItems: queryItems
        )
    }

    func fetchTrip(
        vehicleId: String,
        tripId: String,
        maxPoints: Int = 5000
    ) async throws -> GPSAPITrip {

        let queryItems = [
            URLQueryItem(
                name: "maxPoints",
                value: String(maxPoints)
            )
        ]

        return try await get(
            GPSAPITrip.self,
            path: "/api/v1/vehicles/\(vehicleId)/trips/\(tripId)",
            queryItems: queryItems
        )
    }

    private func get<T: Decodable>(
        _ type: T.Type,
        path: String,
        queryItems: [URLQueryItem] = [],
        requiresAPIKey: Bool = true
    ) async throws -> T {

        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw GPSAPIClientError.invalidURL
        }

        components.path = path
        components.queryItems = queryItems.isEmpty
            ? nil
            : queryItems

        guard let url = components.url else {
            throw GPSAPIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if requiresAPIKey {
            guard let apiKey,
                  !apiKey.trimmingCharacters(
                    in: .whitespacesAndNewlines
                  ).isEmpty else {
                throw GPSAPIClientError.missingAPIKey
            }

            request.setValue(
                apiKey.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                forHTTPHeaderField: "X-API-Key"
            )
        }

        let (data, response) = try await session.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GPSAPIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = try? Self.makeDecoder().decode(
                GPSAPIErrorEnvelope.self,
                from: data
            )

            throw GPSAPIClientError.server(
                statusCode: httpResponse.statusCode,
                code: errorBody?.error.code,
                message: errorBody?.error.message
            )
        }

        return try Self.makeDecoder().decode(
            T.self,
            from: data
        )
    }

    private static func apiTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return formatter.string(from: date)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let supportedFormats: [
                ISO8601DateFormatter.Options
            ] = [
                [.withInternetDateTime, .withFractionalSeconds],
                [.withInternetDateTime]
            ]

            for options in supportedFormats {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = options

                if let date = formatter.date(from: value) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription:
                    "Invalid ISO 8601 timestamp: \(value)"
            )
        }

        return decoder
    }
}

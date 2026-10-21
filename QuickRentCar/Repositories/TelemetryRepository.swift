import Foundation

final class TelemetryRepository {
    static let shared = TelemetryRepository()
    private init() {}

    private let jsonFileName = "QuickRentCar_SeedVehicleTelemetry_JaEla_Colombo"
    private let jsonFileExtension = "json"

    /// Load telemetry from the app bundle (production) or from the Utilities folder (prototype).
    func loadTelemetry() async throws -> VehicleTelemetry {
        // Try loading from the bundle first – this is the normal path when the JSON is packaged.
        print("start load vehicel data")
        if let bundleURL = Bundle.main.url(forResource: jsonFileName, withExtension: jsonFileExtension) {
            let data = try Data(contentsOf: bundleURL)
            let decoder = JSONDecoder.telemetryDecoder
            return try decoder.decode(VehicleTelemetry.self, from: data)
        }
        // Fallback for prototype / preview builds: load the file directly from the project’s Utilities directory.
        let fallbackPath = "\(FileManager.default.currentDirectoryPath)/QuickRentCar/Utilities/\(jsonFileName).\(jsonFileExtension)"
        let fallbackURL = URL(fileURLWithPath: fallbackPath)
        guard FileManager.default.fileExists(atPath: fallbackURL.path) else {
            throw NSError(domain: "TelemetryRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Telemetry JSON not found in bundle nor at fallback path \(fallbackURL.path)"])
        }
        let data = try Data(contentsOf: fallbackURL)
        let decoder = JSONDecoder.telemetryDecoder
        return try decoder.decode(VehicleTelemetry.self, from: data)
    }
}


//final class TelemetryRepository {
//    static let shared = TelemetryRepository()
//    private init() {}
//    
//    private let jsonFileName = "QuickRentCar_SeedVehicleTelemetry_JaEla_Colombo"
//    private let jsonFileExtension = "json"
//    
//    func loadTelemetry() async throws -> VehicleTelemetry {
//        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: jsonFileExtension) else {
//            throw NSError(domain: "TelemetryRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Telemetry JSON file not found in bundle"])
//        }
//        let data = try Data(contentsOf: url)
//        let decoder = JSONDecoder.telemetryDecoder
//        return try decoder.decode(VehicleTelemetry.self, from: data)
//    }
//}

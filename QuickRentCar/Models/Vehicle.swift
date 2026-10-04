import Foundation
import FirebaseFirestore

struct Vehicle: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var brand: String
    var category: VehicleCategory
    var dailyPrice: Double
    var imageURL: String
    var thumbnailURL: String?
    var passengerCapacity: Int
    var fuelType: FuelType
    var transmission: TransmissionType
    var seats: Int
    var includedMileage: Int         // km per day
    var description: String
    var specifications: [String: String]
    var isAvailable: Bool
    var arModelURL: String?           // USDZ model filename for AR
    var rating: Double
    var reviewCount: Int
    var location: String

    enum VehicleCategory: String, Codable, CaseIterable {
        case sedan = "Sedan"
        case suv = "SUV"
        case sports = "Sports"
        case van = "Van"
        case electric = "Electric"
        case luxury = "Luxury"

        var icon: String {
            switch self {
            case .sedan:    return "car.fill"
            case .suv:      return "car.side.fill"
            case .sports:   return "bolt.car.fill"
            case .van:      return "bus.fill"
            case .electric: return "bolt.fill"
            case .luxury:   return "star.fill"
            }
        }
    }

    enum FuelType: String, Codable {
        case petrol = "Petrol"
        case diesel = "Diesel"
        case electric = "Electric"
        case hybrid = "Hybrid"
    }

    enum TransmissionType: String, Codable {
        case automatic = "Automatic"
        case manual = "Manual"
    }
}

// MARK: - Sample Data
extension Vehicle {
    static let sampleVehicles: [Vehicle] = [
        Vehicle(
            id: "1",
            name: "Toyota Camry",
            brand: "Toyota",
            category: .sedan,
            dailyPrice: 65.0,
            imageURL: "vehicle_camry",
            passengerCapacity: 5,
            fuelType: .petrol,
            transmission: .automatic,
            seats: 5,
            includedMileage: 200,
            description: "Comfortable mid-size sedan perfect for city and highway driving.",
            specifications: ["Engine": "2.5L 4-Cylinder", "Horsepower": "203 hp"],
            isAvailable: true,
            rating: 4.5,
            reviewCount: 128,
            location: "Colombo"
        ),
        Vehicle(
            id: "2",
            name: "Honda CR-V",
            brand: "Honda",
            category: .suv,
            dailyPrice: 85.0,
            imageURL: "vehicle_crv",
            passengerCapacity: 5,
            fuelType: .hybrid,
            transmission: .automatic,
            seats: 5,
            includedMileage: 200,
            description: "Versatile hybrid SUV with excellent fuel economy.",
            specifications: ["Engine": "2.0L Hybrid", "Horsepower": "212 hp"],
            isAvailable: true,
            rating: 4.7,
            reviewCount: 94,
            location: "Colombo"
        )
    ]
}

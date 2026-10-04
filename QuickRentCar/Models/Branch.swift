import Foundation

/// The branches a customer can collect a vehicle from and return it to.
///
/// `rawValue` is the string that gets stored in `Vehicle.location` and
/// `Booking.pickupLocation` / `Booking.dropOffLocation`, so it must stay stable.
enum Branch: String, CaseIterable, Identifiable, Codable {
    case katunayakeAirport = "Airport (Katunayake)"
    case colombo = "Colombo"
    case negombo = "Negombo"
    case jaEla = "Ja-Ela"
    case gampaha = "Gampaha"
    case kurunegala = "Kurunegala"

    var id: String { rawValue }

    /// Full name for detail screens; the dropdown uses the shorter `rawValue`.
    var displayName: String {
        switch self {
        case .katunayakeAirport:
            return "Bandaranaike International Airport, Katunayake"
        default:
            return rawValue
        }
    }

    var icon: String {
        switch self {
        case .katunayakeAirport: return "airplane"
        default:                 return "mappin.and.ellipse"
        }
    }
}

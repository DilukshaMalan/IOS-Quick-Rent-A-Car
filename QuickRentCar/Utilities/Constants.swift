import Foundation

enum Constants {
    enum Firestore {
        static let users = "users"
        static let vehicles = "vehicles"
        static let bookings = "bookings"
        static let payments = "payments"
        static let stats = "drivingStats"
    }

    enum UserDefaultsKeys {
        static let isFaceIDEnabled = "isFaceIDEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastKnownFCMToken = "lastKnownFCMToken"
    }

    enum NotificationNames {
        static let bookingConfirmed = "BookingConfirmed"
        static let pickupReminder = "PickupReminder"
        static let returnReminder = "ReturnReminder"
    }

    enum Pricing {
        static let currency = "LKR"
        static let taxRate: Double = 0.10
    }

    enum Location {
        static let geofenceRadiusMeters: Double = 200
        static let defaultRegion = "Colombo, Sri Lanka"
    }

    enum OCR {
        static let minimumConfidence: Float = 0.5
    }
}

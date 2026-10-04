import Foundation

enum Constants {
    // MARK: - Firestore Collections
    enum Firestore {
        static let users = "users"
        static let vehicles = "vehicles"
        static let bookings = "bookings"
        static let payments = "payments"
        static let stats = "drivingStats"
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let isFaceIDEnabled = "isFaceIDEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastKnownFCMToken = "lastKnownFCMToken"
    }

    // MARK: - App Group (for WidgetKit)
    static let appGroupID = "group.com.quickrentcar.app"

    // MARK: - Notification Names
    enum NotificationNames {
        static let bookingConfirmed = "BookingConfirmed"
        static let pickupReminder = "PickupReminder"
        static let returnReminder = "ReturnReminder"
    }

    // MARK: - Pricing
    enum Pricing {
        static let currency = "LKR"
        static let taxRate: Double = 0.10  // 10% tax
    }

    // MARK: - Location
    enum Location {
        static let geofenceRadiusMeters: Double = 200
        static let defaultRegion = "Colombo, Sri Lanka"
    }

    // MARK: - AR
    enum AR {
        static let defaultModelName = "generic_car"
        static let modelExtension = "usdz"
    }

    // MARK: - OCR
    enum OCR {
        static let minimumConfidence: Float = 0.5
    }
}

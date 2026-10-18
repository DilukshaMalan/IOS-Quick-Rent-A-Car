import Foundation

@MainActor
class BookingViewModel: ObservableObject {
    @Published var pickupDate: Date
    @Published var returnDate: Date
    @Published var pickupLocation: String
    @Published var dropOffLocation: String
    @Published var isLoading = false
    @Published var isCheckingAvailability = false
    @Published var errorMessage: String?
    @Published var confirmedBookingId: String?
    @Published var bookingSuccess = false

    /// Re-read from Firestore by `refreshAvailability()` so `bookedPeriods` is current.
    @Published private(set) var vehicle: Vehicle

    private let firestoreService = FirestoreService.shared
    private let notificationService = NotificationService.shared

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        // The car is collected from its own branch, and by default returned there too.
        self.pickupLocation = vehicle.location
        self.dropOffLocation = vehicle.location

        // Realistic defaults: tomorrow 09:00, 3-day rental
        let pickup = Self.defaultPickupDate()
        self.pickupDate = pickup
        self.returnDate = pickup.adding(days: 3)
    }

    /// Tomorrow at 09:00 — better than "right now" as a starting point.
    private static func defaultPickupDate() -> Date {
        let tomorrow = Date().adding(days: 1)
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    // MARK: - Computed Price
    var rentalDays: Int {
        pickupDate.days(to: returnDate)
    }

    var subtotal: Double {
        vehicle.dailyPrice * Double(rentalDays)
    }

    var taxAmount: Double {
        PriceCalculator.taxAmount(subtotal: subtotal)
    }

    var totalPrice: Double {
        subtotal + taxAmount
    }

    // MARK: - Availability
    var bookingPeriod: DateRange {
        DateRange(start: pickupDate, end: returnDate)
    }

    var isVehicleAvailable: Bool {
        vehicle.canBeBooked(for: bookingPeriod)
    }

    /// What the availability banner should show. `nil` while the dates themselves are invalid.
    var availabilityState: BookingAvailabilityState? {
        guard returnDate > pickupDate else { return nil }
        guard vehicle.isAvailable else { return .unavailable }
        if let conflict = (vehicle.bookedPeriods ?? []).first(where: { $0.overlaps(bookingPeriod) }) {
            return .booked(conflict)
        }
        return .available
    }

    /// Re-reads the vehicle so availability reflects bookings made since the list loaded.
    /// Failures are ignored on purpose: the booking transaction re-checks on the server anyway.
    func refreshAvailability() async {
        guard let id = vehicle.id else { return }
        isCheckingAvailability = true
        defer { isCheckingAvailability = false }

        if let fresh = try? await firestoreService.fetchVehicle(id: id) {
            vehicle = fresh
        }
    }

    // MARK: - Validation
    var isFormValid: Bool {
        pickupLocation.isNotEmpty &&
        dropOffLocation.isNotEmpty &&
        returnDate > pickupDate &&
        isVehicleAvailable
    }

    /// Why the form can't continue yet (shown under the Continue button).
    var validationHint: String? {
        if !pickupLocation.isNotEmpty || !dropOffLocation.isNotEmpty {
            return "Choose a drop-off branch to continue."
        }
        if returnDate <= pickupDate {
            return "Return time must be after the pick-up time."
        }
        if !isVehicleAvailable {
            return "This vehicle isn't available for the selected dates."
        }
        return nil
    }

    // MARK: - Confirm Booking
    func confirmBooking(userId: String) async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let booking = Booking(
            userId: userId,
            vehicleId: vehicle.id ?? "",
            vehicleName: vehicle.name,
            vehicleImageURL: vehicle.imageURL,
            pickupLocation: pickupLocation,
            dropOffLocation: dropOffLocation,
            pickupDate: pickupDate,
            returnDate: returnDate,
            totalDays: rentalDays,
            dailyRate: vehicle.dailyPrice,
            totalPrice: totalPrice
        )

        do {
            let bookingId = try await firestoreService.createBooking(booking)
            confirmedBookingId = bookingId

            // Schedule notifications
            notificationService.schedulePickupReminder(
                bookingId: bookingId,
                vehicleName: vehicle.name,
                pickupDate: pickupDate
            )
            notificationService.scheduleReturnReminder(
                bookingId: bookingId,
                vehicleName: vehicle.name,
                returnDate: returnDate
            )

            bookingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

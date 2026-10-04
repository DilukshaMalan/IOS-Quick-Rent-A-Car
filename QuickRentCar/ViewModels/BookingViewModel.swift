import Foundation

@MainActor
class BookingViewModel: ObservableObject {
    @Published var pickupDate = Date()
    @Published var returnDate = Date().adding(days: 3)
    @Published var pickupLocation = ""
    @Published var dropOffLocation = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var confirmedBookingId: String?
    @Published var bookingSuccess = false

    let vehicle: Vehicle
    private let firestoreService = FirestoreService.shared
    private let notificationService = NotificationService.shared

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
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

    var isFormValid: Bool {
        pickupLocation.isNotEmpty &&
        dropOffLocation.isNotEmpty &&
        returnDate > pickupDate
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

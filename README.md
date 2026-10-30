# IOS-Quick-Rent-A-Car

An iOS car rental app for long-term vehicle hire in Sri Lanka. Customers rent a vehicle for weeks or months, drive it freely, and collect it again from wherever it is currently parked. The app scans the driving licence on the device, tracks the vehicle through an external GPS service, and navigates the customer to it.

Built with SwiftUI for iOS 17.0 and later. Runs on both iPhone and iPad.

---

## Features

- **Email sign-in** through Firebase Authentication, with optional Face ID unlock
- **Vehicle catalogue** with branch, date and category search, filtered by real availability
- **Booking flow** with rental period selection and automatic price and tax calculation
- **Driving licence scanning** using the Vision framework, entirely on the device
- **Geofencing** with Core Location, notifying the customer on arrival at collection and return zones
- **Vehicle navigation** from the customer's location to the vehicle's last known GPS position
- **Driving statistics** showing distance, speeds, driving time and mileage package usage
- **Journey replay** animating the vehicle along its recorded route on a map
- **iPad layouts** that change structure rather than scaling the iPhone design

---

## Requirements

- Xcode 15 or later
- iOS 17.0 or later (simulator or device)
- Swift 5

---

## Setup

### 1. Clone and open

```bash
git clone https://github.com/DilukshaMalan/IOS-Quick-Rent-A-Car.git
cd IOS-Quick-Rent-A-Car
open QuickRentCar.xcodeproj
```

Swift Package Manager resolves the Firebase dependency automatically on first open. Wait for it to finish before building.

### 2. Add the GPS API key

The API key is not stored in this repository. Copy the example file and add the key supplied with the submission:

```bash
cp QuickRentCar/Secrets.example.xcconfig QuickRentCar/Secrets.xcconfig
```

Then open `QuickRentCar/Secrets.xcconfig` and replace the placeholder:

```
GPS_API_KEY = <the read-only key supplied with the submission>
```

Xcode substitutes this value into `Info.plist` at build time. The app reads it from there and sends it as an `X-API-Key` header.

Without the key, the app builds and runs, but the Stats tab and the vehicle navigation screen show an error instead of data.

### 3. Build and run

Select any iPhone or iPad simulator and run. `GoogleService-Info.plist` for Firebase is already included.

---

## Backend services

### Firebase

Handles accounts and rental data: Authentication for sign-in, Cloud Firestore for the `users`, `vehicles`, `bookings` and `payments` collections, and Cloud Messaging for notifications.

A test account is supplied with the submission. The Face ID prompt can be dismissed — the app falls back to normal sign-in.

### GPS telemetry API

A separate service I built for this project. It supplies vehicle position data only. It knows nothing about rentals, rental periods or mileage packages — the app derives all of that from the raw position stream, which is how a real fleet tracker works.

- **Source:** https://github.com/DilukshaMalan/gps-api-2
- **Base URL:** `https://gps-api-2-production.up.railway.app`
- **Stack:** Node.js with no runtime dependencies, deployed on Railway

**Access for markers.** The deployed service is read-only. Every endpoint is a `GET`, there is no write path of any kind, and the data is static, so nothing you do can alter or damage it.

Health check, no key needed:

```bash
curl https://gps-api-2-production.up.railway.app/api/v1/health
```

Authenticated requests use the `X-API-Key` header with the read-only key supplied with the submission:

```bash
curl -H "X-API-Key: <marker key>" \
  https://gps-api-2-production.up.railway.app/api/v1/vehicles

curl -H "X-API-Key: <marker key>" \
  "https://gps-api-2-production.up.railway.app/api/v1/vehicles/QR-001/position"

curl -H "X-API-Key: <marker key>" \
  "https://gps-api-2-production.up.railway.app/api/v1/vehicles/QR-001/trips?from=2026-10-10T00:00:00Z&to=2026-10-23T23:59:59Z"
```

**Endpoints**

| Endpoint | Returns | Key |
| --- | --- | --- |
| `GET /api/v1/health` | Service status and vehicle count | No |
| `GET /api/v1/vehicles` | All vehicles with data range and last known position | Yes |
| `GET /api/v1/vehicles/{id}/position` | Newest position for one vehicle | Yes |
| `GET /api/v1/vehicles/{id}/trips` | Trips in a date range, points optional | Yes |
| `GET /api/v1/vehicles/{id}/trips/{tripId}` | One trip in full | Yes |

The trips endpoint takes `from` and `to` as ISO 8601 timestamps, plus `includePoints` and `maxPoints`. A range wider than 31 days is refused with `range_too_large`. A trip with more points than `maxPoints` is evenly downsampled, and the effective interval is reported in the response metadata.

**Sample data:** vehicles `QR-001`, `QR-002` and `QR-003`, covering 10 to 23 October 2026 in Sri Lanka time, sampled every five seconds. The data is synthetic and is labelled as such in the response metadata.

---

## Notes for markers

- **Stats tab** reports on vehicle `QR-001`. Because the sample data is a fixed window, the statistics periods are anchored to the newest telemetry point rather than to the real current date, so Today, Week and Month show data instead of zeroes. This is controlled by `useSampleDataAnchor` in `VehicleStatsViewModel`.
- **Vehicle navigation** appears only on bookings whose status is `Active` or `Confirmed`. Booking status is held in Firestore and is not advanced automatically, so to see the navigation screen, open the `bookings` collection in the Firebase console, set a booking's `status` field to `Active`, then pull to refresh the Bookings tab.
- **Navigation origin** is fixed to Bandaranaike International Airport so the route is reproducible on a simulator with no location fix. The real device location replaces one constant in `VehicleNavigationViewModel`.
- **Geofences** can be exercised in the simulator with Features → Location → Custom Location.
- **Licence scanning** works best with a well-lit, straight-on photograph. The gallery picker can be used instead of the camera on a simulator.
- **iPad layouts** differ from iPhone in the catalogue grid, the vehicle detail layout and the statistics card arrangement. Run on both to see the difference.

---

## Tests

77 XCTest cases across 15 files, covering price and date calculation, booking availability overlap, telemetry decoding and statistics, OCR error handling, and view model validation.

Run with **Product → Test**, or:

```bash
xcodebuild test -scheme QuickRentCar -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Project structure

```
QuickRentCar/
├── App/              App entry point, ContentView, AppDelegate
├── Models/           Codable data types, including Telemetry models
├── ViewModels/       @MainActor observable objects holding presentation state
├── Views/            SwiftUI screens, grouped by feature
├── Services/         Firebase, Vision OCR, Core Location, routing, GPS API client
├── Repositories/     Sits between services and view models
├── Utilities/        Constants, extensions, helpers
└── Resources/        Assets and the asset catalogue

QuickRentCarTests/    Unit tests, mirroring the source structure
```

The app follows MVVM. Views hold no logic, view models make no framework or network calls, and every external call is made from the service layer.

---

## Author

Diluksha Malan — BSc (Hons) Software Engineering, National Institute of Business Management

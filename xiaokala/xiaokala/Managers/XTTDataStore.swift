//
//  XTTDataStore.swift
//  xiaokala — X Drive Log
//
//  Offline-first JSON persistence via FileManager. Single source of truth
//  for all domain records. Supports a non-persisting guest mode.
//

import Foundation

/// Posted whenever the underlying data set changes so screens can refresh.
extension Notification.Name {
    static let xttDataChanged = Notification.Name("XTTDataChangedNotification")
}

final class XTTDataStore {

    static let shared = XTTDataStore()

    // MARK: - In-memory state

    private(set) var vehicles: [XTTVehicle] = []
    private(set) var trips: [XTTTrip] = []
    private(set) var fuelEntries: [XTTFuelEntry] = []
    private(set) var maintenance: [XTTMaintenance] = []

    /// When true, nothing is written to disk (guest mode).
    private(set) var isGuestMode = false

    // MARK: - Paths

    private let fileName = "xtt_drive_log.json"

    private var storeURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private struct Snapshot: Codable {
        var vehicles: [XTTVehicle]
        var trips: [XTTTrip]
        var fuelEntries: [XTTFuelEntry]
        var maintenance: [XTTMaintenance]
    }

    private init() {}

    // MARK: - Session lifecycle

    /// Loads persisted data for an authenticated session.
    func startAuthenticatedSession() {
        isGuestMode = false
        load()
    }

    /// Starts an ephemeral guest session with sample data and no persistence.
    func startGuestSession() {
        isGuestMode = true
        vehicles = []
        trips = []
        fuelEntries = []
        maintenance = []
        seedSampleData()
        broadcast()
    }

    /// Clears the in-memory guest data. Called on guest sign-out.
    func endGuestSession() {
        guard isGuestMode else { return }
        vehicles = []
        trips = []
        fuelEntries = []
        maintenance = []
        isGuestMode = false
        broadcast()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else {
            vehicles = []; trips = []; fuelEntries = []; maintenance = []
            broadcast()
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            vehicles = snapshot.vehicles
            trips = snapshot.trips
            fuelEntries = snapshot.fuelEntries
            maintenance = snapshot.maintenance
        }
        broadcast()
    }

    private func persist() {
        guard !isGuestMode else { return }
        let snapshot = Snapshot(vehicles: vehicles,
                                trips: trips,
                                fuelEntries: fuelEntries,
                                maintenance: maintenance)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    private func broadcast() {
        NotificationCenter.default.post(name: .xttDataChanged, object: nil)
    }

    private func commit() {
        persist()
        broadcast()
    }

    // MARK: - Vehicles

    func addVehicle(_ vehicle: XTTVehicle) {
        vehicles.append(vehicle)
        commit()
    }

    func updateVehicle(_ vehicle: XTTVehicle) {
        guard let idx = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        vehicles[idx] = vehicle
        commit()
    }

    func deleteVehicle(_ vehicle: XTTVehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        // Cascade delete related records.
        trips.removeAll { $0.vehicleID == vehicle.id }
        fuelEntries.removeAll { $0.vehicleID == vehicle.id }
        maintenance.removeAll { $0.vehicleID == vehicle.id }
        commit()
    }

    func vehicle(withID id: UUID) -> XTTVehicle? {
        vehicles.first { $0.id == id }
    }

    // MARK: - Trips

    func addTrip(_ trip: XTTTrip) {
        trips.append(trip)
        bumpOdometerIfNeeded(vehicleID: trip.vehicleID, delta: trip.distance)
        commit()
    }

    func updateTrip(_ trip: XTTTrip) {
        guard let idx = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[idx] = trip
        commit()
    }

    func deleteTrip(_ trip: XTTTrip) {
        trips.removeAll { $0.id == trip.id }
        commit()
    }

    func trips(for vehicleID: UUID) -> [XTTTrip] {
        trips.filter { $0.vehicleID == vehicleID }.sorted { $0.date > $1.date }
    }

    // MARK: - Fuel

    func addFuel(_ entry: XTTFuelEntry) {
        fuelEntries.append(entry)
        setOdometerIfHigher(vehicleID: entry.vehicleID, reading: entry.odometer)
        commit()
    }

    func updateFuel(_ entry: XTTFuelEntry) {
        guard let idx = fuelEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        fuelEntries[idx] = entry
        commit()
    }

    func deleteFuel(_ entry: XTTFuelEntry) {
        fuelEntries.removeAll { $0.id == entry.id }
        commit()
    }

    func fuelEntries(for vehicleID: UUID) -> [XTTFuelEntry] {
        fuelEntries.filter { $0.vehicleID == vehicleID }.sorted { $0.date > $1.date }
    }

    // MARK: - Maintenance

    func addMaintenance(_ item: XTTMaintenance) {
        maintenance.append(item)
        setOdometerIfHigher(vehicleID: item.vehicleID, reading: item.odometer)
        commit()
    }

    func updateMaintenance(_ item: XTTMaintenance) {
        guard let idx = maintenance.firstIndex(where: { $0.id == item.id }) else { return }
        maintenance[idx] = item
        commit()
    }

    func deleteMaintenance(_ item: XTTMaintenance) {
        maintenance.removeAll { $0.id == item.id }
        commit()
    }

    func maintenance(for vehicleID: UUID) -> [XTTMaintenance] {
        maintenance.filter { $0.vehicleID == vehicleID }.sorted { $0.date > $1.date }
    }

    // MARK: - Odometer helpers

    private func bumpOdometerIfNeeded(vehicleID: UUID, delta: Double) {
        guard let idx = vehicles.firstIndex(where: { $0.id == vehicleID }) else { return }
        vehicles[idx].odometer += delta
    }

    private func setOdometerIfHigher(vehicleID: UUID, reading: Double) {
        guard let idx = vehicles.firstIndex(where: { $0.id == vehicleID }) else { return }
        if reading > vehicles[idx].odometer {
            vehicles[idx].odometer = reading
        }
    }

    // MARK: - Export

    /// Returns a pretty-printed JSON export of all data, or nil on failure.
    func exportJSONData() -> Data? {
        let snapshot = Snapshot(vehicles: vehicles,
                                trips: trips,
                                fuelEntries: fuelEntries,
                                maintenance: maintenance)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(snapshot)
    }

    // MARK: - Sample data (guest mode only)

    private func seedSampleData() {
        let v = XTTVehicle(name: "My Daily",
                           make: "Tesla",
                           model: "Model 3",
                           year: 2022,
                           plate: "XDL-2022",
                           fuelType: .electric,
                           odometer: 24850,
                           colorHex: "3399FF")
        vehicles = [v]

        let now = Date()
        let day: TimeInterval = 86400
        trips = [
            XTTTrip(vehicleID: v.id, startPlace: "Home", endPlace: "Office",
                    distance: 18.4, purpose: .commute, note: "", date: now),
            XTTTrip(vehicleID: v.id, startPlace: "Office", endPlace: "Gym",
                    distance: 6.2, purpose: .personal, note: "", date: now - day),
            XTTTrip(vehicleID: v.id, startPlace: "Home", endPlace: "Client HQ",
                    distance: 42.9, purpose: .business, note: "Q3 review", date: now - day * 3)
        ]

        fuelEntries = [
            XTTFuelEntry(vehicleID: v.id, amount: 22.40, liters: 0,
                         odometer: 24700, isFull: true, station: "Supercharger",
                         date: now - day * 2)
        ]

        maintenance = [
            XTTMaintenance(vehicleID: v.id, title: "Tire rotation",
                           kind: .service, cost: 40, odometer: 24500,
                           note: "", date: now - day * 10)
        ]
    }

    // MARK: - Demo account seeding (persisted)

    /// Populates the persisted store with a rich, realistic data set spanning
    /// the last several months. Used to prime the bundled demo account.
    func seedDemoDataToDisk() {
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: -n, to: now) ?? now
        }

        // Two vehicles: a petrol commuter and a diesel weekend SUV.
        let civic = XTTVehicle(name: "Daily Commuter",
                               make: "Honda",
                               model: "Civic",
                               year: 2021,
                               plate: "XDL-1180",
                               fuelType: .gasoline,
                               odometer: 41260,
                               colorHex: "3399FF")
        let cx5 = XTTVehicle(name: "Weekend SUV",
                             make: "Mazda",
                             model: "CX-5",
                             year: 2019,
                             plate: "TRK-4420",
                             fuelType: .diesel,
                             odometer: 88540,
                             colorHex: "FF9933")
        vehicles = [civic, cx5]

        // Trips across ~5 months so the distance chart shows a trend.
        trips = [
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Office",
                    distance: 21.6, purpose: .commute, note: "", date: daysAgo(0)),
            XTTTrip(vehicleID: civic.id, startPlace: "Office", endPlace: "Home",
                    distance: 21.6, purpose: .commute, note: "", date: daysAgo(1)),
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Supermarket",
                    distance: 8.3, purpose: .personal, note: "Weekly groceries", date: daysAgo(3)),
            XTTTrip(vehicleID: cx5.id, startPlace: "Home", endPlace: "Lakeside Cabin",
                    distance: 143.7, purpose: .personal, note: "Weekend trip", date: daysAgo(6)),
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Client HQ",
                    distance: 54.2, purpose: .business, note: "Contract signing", date: daysAgo(12)),
            XTTTrip(vehicleID: civic.id, startPlace: "Office", endPlace: "Airport",
                    distance: 33.9, purpose: .business, note: "Pickup", date: daysAgo(19)),
            XTTTrip(vehicleID: cx5.id, startPlace: "Home", endPlace: "Mountain Trailhead",
                    distance: 96.5, purpose: .personal, note: "", date: daysAgo(27)),
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Office",
                    distance: 21.6, purpose: .commute, note: "", date: daysAgo(41)),
            XTTTrip(vehicleID: cx5.id, startPlace: "Home", endPlace: "Coast Road",
                    distance: 210.4, purpose: .personal, note: "Road trip", date: daysAgo(63)),
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Conference Center",
                    distance: 47.8, purpose: .business, note: "Annual expo", date: daysAgo(88)),
            XTTTrip(vehicleID: civic.id, startPlace: "Home", endPlace: "Office",
                    distance: 21.6, purpose: .commute, note: "", date: daysAgo(119)),
            XTTTrip(vehicleID: cx5.id, startPlace: "Home", endPlace: "Ski Resort",
                    distance: 178.2, purpose: .personal, note: "Season opener", date: daysAgo(146))
        ]

        // Fuel fill-ups across months for the cost trend.
        fuelEntries = [
            XTTFuelEntry(vehicleID: civic.id, amount: 58.30, liters: 42.1,
                         odometer: 41180, isFull: true, station: "Shell", date: daysAgo(2)),
            XTTFuelEntry(vehicleID: cx5.id, amount: 82.40, liters: 55.4,
                         odometer: 88400, isFull: true, station: "BP", date: daysAgo(8)),
            XTTFuelEntry(vehicleID: civic.id, amount: 55.90, liters: 40.5,
                         odometer: 40760, isFull: true, station: "Costco", date: daysAgo(24)),
            XTTFuelEntry(vehicleID: cx5.id, amount: 88.10, liters: 58.9,
                         odometer: 87950, isFull: true, station: "Esso", date: daysAgo(48)),
            XTTFuelEntry(vehicleID: civic.id, amount: 60.20, liters: 43.6,
                         odometer: 40210, isFull: true, station: "Shell", date: daysAgo(74)),
            XTTFuelEntry(vehicleID: cx5.id, amount: 79.60, liters: 53.8,
                         odometer: 87360, isFull: true, station: "BP", date: daysAgo(101)),
            XTTFuelEntry(vehicleID: civic.id, amount: 57.40, liters: 41.9,
                         odometer: 39680, isFull: true, station: "Costco", date: daysAgo(133))
        ]

        // Maintenance history.
        maintenance = [
            XTTMaintenance(vehicleID: civic.id, title: "Oil & filter change",
                           kind: .service, cost: 89.00, odometer: 41000,
                           note: "5W-30 synthetic", date: daysAgo(15)),
            XTTMaintenance(vehicleID: cx5.id, title: "Brake pads (front)",
                           kind: .replacement, cost: 240.00, odometer: 88100,
                           note: "OEM pads", date: daysAgo(34)),
            XTTMaintenance(vehicleID: civic.id, title: "Tire rotation",
                           kind: .service, cost: 40.00, odometer: 40500,
                           note: "", date: daysAgo(58)),
            XTTMaintenance(vehicleID: cx5.id, title: "Annual inspection",
                           kind: .inspection, cost: 55.00, odometer: 87800,
                           note: "Passed", date: daysAgo(92)),
            XTTMaintenance(vehicleID: civic.id, title: "Cabin air filter",
                           kind: .replacement, cost: 28.50, odometer: 39900,
                           note: "", date: daysAgo(126)),
            XTTMaintenance(vehicleID: cx5.id, title: "Wiper blades",
                           kind: .repair, cost: 32.00, odometer: 87100,
                           note: "Both front", date: daysAgo(150))
        ]

        // Persist directly (authenticated store, not guest).
        let snapshot = Snapshot(vehicles: vehicles,
                                trips: trips,
                                fuelEntries: fuelEntries,
                                maintenance: maintenance)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }
}

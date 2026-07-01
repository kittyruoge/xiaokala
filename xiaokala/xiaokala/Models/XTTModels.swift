//
//  XTTModels.swift
//  xiaokala — X Drive Log
//
//  Codable domain models. All persisted locally as JSON.
//

import Foundation

// MARK: - Vehicle

enum XTTFuelType: String, Codable, CaseIterable {
    case gasoline = "Gasoline"
    case diesel = "Diesel"
    case electric = "Electric"
    case hybrid = "Hybrid"
    case lpg = "LPG"

    var symbolName: String {
        switch self {
        case .gasoline: return "fuelpump.fill"
        case .diesel: return "fuelpump.fill"
        case .electric: return "bolt.car.fill"
        case .hybrid: return "leaf.fill"
        case .lpg: return "flame.fill"
        }
    }
}

struct XTTVehicle: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var make: String
    var model: String
    var year: Int
    var plate: String
    var fuelType: XTTFuelType
    var odometer: Double        // current reading, km
    var colorHex: String        // accent tag colour
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         make: String,
         model: String,
         year: Int,
         plate: String,
         fuelType: XTTFuelType,
         odometer: Double,
         colorHex: String,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.plate = plate
        self.fuelType = fuelType
        self.odometer = odometer
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    var displaySubtitle: String {
        let parts = ["\(year)", make, model].filter { !$0.isEmpty && $0 != "0" }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Trip

enum XTTTripPurpose: String, Codable, CaseIterable {
    case personal = "Personal"
    case business = "Business"
    case commute = "Commute"
    case other = "Other"

    var symbolName: String {
        switch self {
        case .personal: return "person.fill"
        case .business: return "briefcase.fill"
        case .commute: return "building.2.fill"
        case .other: return "mappin.and.ellipse"
        }
    }
}

struct XTTTrip: Codable, Identifiable, Equatable {
    var id: UUID
    var vehicleID: UUID
    var startPlace: String
    var endPlace: String
    var distance: Double        // km
    var purpose: XTTTripPurpose
    var note: String
    var date: Date

    init(id: UUID = UUID(),
         vehicleID: UUID,
         startPlace: String,
         endPlace: String,
         distance: Double,
         purpose: XTTTripPurpose,
         note: String = "",
         date: Date = Date()) {
        self.id = id
        self.vehicleID = vehicleID
        self.startPlace = startPlace
        self.endPlace = endPlace
        self.distance = distance
        self.purpose = purpose
        self.note = note
        self.date = date
    }

    var route: String { "\(startPlace) → \(endPlace)" }
}

// MARK: - Fuel

struct XTTFuelEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var vehicleID: UUID
    var amount: Double          // total cost
    var liters: Double
    var odometer: Double        // reading at fill-up, km
    var isFull: Bool
    var station: String
    var date: Date

    init(id: UUID = UUID(),
         vehicleID: UUID,
         amount: Double,
         liters: Double,
         odometer: Double,
         isFull: Bool = true,
         station: String = "",
         date: Date = Date()) {
        self.id = id
        self.vehicleID = vehicleID
        self.amount = amount
        self.liters = liters
        self.odometer = odometer
        self.isFull = isFull
        self.station = station
        self.date = date
    }

    /// Price per litre; guards against divide-by-zero.
    var pricePerLiter: Double {
        liters > 0 ? amount / liters : 0
    }
}

// MARK: - Maintenance

enum XTTMaintenanceKind: String, Codable, CaseIterable {
    case service = "Service"
    case repair = "Repair"
    case replacement = "Replacement"
    case inspection = "Inspection"
    case other = "Other"

    var symbolName: String {
        switch self {
        case .service: return "wrench.and.screwdriver.fill"
        case .repair: return "hammer.fill"
        case .replacement: return "arrow.triangle.2.circlepath"
        case .inspection: return "checkmark.seal.fill"
        case .other: return "gearshape.fill"
        }
    }
}

struct XTTMaintenance: Codable, Identifiable, Equatable {
    var id: UUID
    var vehicleID: UUID
    var title: String
    var kind: XTTMaintenanceKind
    var cost: Double
    var odometer: Double
    var note: String
    var date: Date

    init(id: UUID = UUID(),
         vehicleID: UUID,
         title: String,
         kind: XTTMaintenanceKind,
         cost: Double,
         odometer: Double,
         note: String = "",
         date: Date = Date()) {
        self.id = id
        self.vehicleID = vehicleID
        self.title = title
        self.kind = kind
        self.cost = cost
        self.odometer = odometer
        self.note = note
        self.date = date
    }
}

// MARK: - Cost category

enum XTTCostCategory: String, CaseIterable {
    case fuel = "Fuel"
    case maintenance = "Maintenance"
    case other = "Other"
}

// MARK: - User account (local only)

struct XTTAccount: Codable, Equatable {
    var email: String
    var displayName: String
    /// Salted SHA256 hash of the password. Plain text is never stored.
    var passwordHash: String
    var salt: String
    var createdAt: Date
}

//
//  Lightning.swift
//  FinalDEVChallenge2022
//

import Foundation

// MARK: - Lightning
typealias LightningResult = [Lightning]

struct Lightning: Codable {
    let sensorID: String
    let lat, lon, timestamp: Double
    let eventID: String
    var db: String?

    enum CodingKeys: String, CodingKey {
        case sensorID = "sensorId"
        case lat, lon, timestamp
        case eventID = "eventId"
    }
}

extension Lightning: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sensorID == rhs.sensorID &&
        lhs.eventID == rhs.eventID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sensorID)
        hasher.combine(eventID)
    }
}

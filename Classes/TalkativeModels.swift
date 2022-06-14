import Foundation

struct WidgetMatcherResponse: Codable {
    let configUuid: String
    let version: String
}

struct ConfigResponse: Codable {
    let presences: [PresenceObj]
}

struct PresenceObj: Codable {
    let queueUuid: String
    let status: String
}

/// Service availability enum
public enum AvailabilityStatus: Equatable {
    case online
    case offline
    case error(desc: String)
}

public struct InteractionDataEntry: Codable {
    let label, name, data, type: String
}

public struct Qos: Codable {
    let video, chat: Bool
}

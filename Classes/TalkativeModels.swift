import Foundation

struct OnlineResponse: Codable {
    let status: String
    let features: Features
}

/// Service availability enum
public enum AvailabilityStatus: Equatable {
    case chatOnly
    case videoOnly
    case chatAndVideo
    case offline
    case error(desc: String)
    
    func isCommunicationAvailable(type: CommunicationType) -> Bool {
        switch type {
        case .chat: return (self == .chatOnly || self == .chatAndVideo)
        case .video: return (self == .videoOnly || self == .chatAndVideo)
        }
    }
}

struct Features: Codable {
    let chat, video: Bool
}

struct Reasons: Codable {
    let chat, video: String
}

public struct InteractionDataEntry: Codable {
    let label, data, type: String
}

struct MessageBody: Codable {
    let ready, final: Bool?
    let qos: String?
}

struct Qos: Codable {
    let video, chat: Bool
}

public enum CommunicationType: String {
    case chat = "chat"
    case video = "video"
}

public enum QosFail: Error {
    case slowInternet
    case noActiveUser
    case general(String)
    case notAvailable
}



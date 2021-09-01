import Foundation

struct OnlineResponse: Codable {
    let status: String
    let features: Features
}

struct Features: Codable {
    let chat, video: Bool
}

struct Reasons: Codable {
    let chat, video: String
}

struct InteractionDataEntry: Codable {
    let label, data, type: String
}

struct MessageBody: Codable {
    let ready, final: Bool?
    let qos: String?
}

struct Qos: Codable {
    let video, chat: Bool
}

enum CommunicationType: String {
    case chat = "chat"
    case video = "video"
}

enum QosFail: Error {
    case slowInternet
    case noActiveUser
    case general(String)
}



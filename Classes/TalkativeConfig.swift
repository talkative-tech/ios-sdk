import Foundation

public struct TalkativeConfig {
    var companyId: String
    var queueId: String
    var region: String
    var color: String
    var type: CommunicationType
    var interactionData: Array<InteractionDataEntry>
    var signedInteractionData: String
}

extension TalkativeConfig {
    public static func defaultConfig(companyId: String, queueId: String, region: String) -> TalkativeConfig {
        return TalkativeConfig(
            companyId: companyId,
            queueId: queueId,
            region: region,
            color: "255,0,0",
            type: .chat,
            interactionData: [InteractionDataEntry(label: "Name", data: "John", type: "string")],
            signedInteractionData: ""
        )
    }
}

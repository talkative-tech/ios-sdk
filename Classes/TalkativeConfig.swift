import Foundation

public struct TalkativeConfig {
    var companyId: String
    var queueId: String
    var region: String
    var color: String
    var type: CommunicationType
    var interactionData: Array<InteractionDataEntry>
    var signedInteractionData: String
    var extraUrlParams: String
}

extension TalkativeConfig {
    public static func defaultConfig(companyId: String, queueId: String, region: String, interactionData: Array<InteractionDataEntry> = [], signedInteractionData: String = "", color: String = "255,0,0", extraUrlParams: String = "") -> TalkativeConfig {
        return TalkativeConfig(
            companyId: companyId,
            queueId: queueId,
            region: region,
            color: color,
            type: .chat,
            interactionData: interactionData,
            signedInteractionData: signedInteractionData,
            extraUrlParams: extraUrlParams
        )
    }
}

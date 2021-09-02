//
//  TalkativeConfig.swift
//  CustomerScriptsEmbed
//
//  Created by mert on 01/09/2021.
//

import Foundation

struct TalkativeConfig {
    var companyId: String
    var queueId: String
    var region: String
    var color: String
    var type: CommunicationType
    var interactionData: Array<InteractionDataEntry>
    var signedInteractionData: String
}

extension TalkativeConfig {
    static func defaultConfig(companyId: String, queueId: String, region: String) -> TalkativeConfig {
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

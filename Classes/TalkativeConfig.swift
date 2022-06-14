import Foundation

public struct TalkativeConfig {
    var widgetUuid: String
    var region: String
var widgetPath: String
    var actionable: String?
    var interactionData: Array<InteractionDataEntry>
    var signedInteractionData: String
    var extraUrlParams: String
}

extension TalkativeConfig {
    public static func defaultConfig(widgetUuid: String, region: String, widgetPath: String = "https://engage.app/mobile-app", interactionData: Array<InteractionDataEntry> = [], signedInteractionData: String = "", extraUrlParams: String = "") -> TalkativeConfig {
        return TalkativeConfig(
            widgetUuid: widgetUuid,
            region: region,
            widgetPath: widgetPath,
            actionable: nil,
            interactionData: interactionData,
            signedInteractionData: signedInteractionData,
            extraUrlParams: extraUrlParams
        )
    }
    
    public func getUrlFromRegion() -> String {
        switch region {
        case "eu":
            return "https://eu.engage.app"
        case "us":
            return "https://us.engage.app"
        case "au":
            return "https://au.engage.app"
        case "staging":
            return "https://salesforce.engage.app"
        default:
            fatalError("Invalid region passed to Talkative config")
        }
    }
}

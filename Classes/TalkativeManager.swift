import Foundation
import UIKit

let talkativeServerDomain: String! = "https://talkative-cdn.com/mobile-embed/0.1.0/index.html"

public class TalkativeManager {
    // General SDK Configuration
    public var config: TalkativeConfig?
    // Delegates for informing app about conversation status
    public weak var serviceDelegate: TalkativeServerDelegate?
    private var vc: TalkativeViewController? = nil
    public static let shared = TalkativeManager()
    
    /// Starts interaction by giving TalkativeViewController to user where
    /// they can manage routing
    /// - Parameter type: Communication type .chat or .video
    /// - Returns: Optional view controller in the case of error
    public func startInteraction(actionable: String? = nil) -> TalkativeViewController? {
        self.config?.actionable = actionable
        
        guard let conf = config else {
            NSLog("Talkative config is not correctly set!")
            return nil
        }
        
        self.vc = TalkativeViewController(with: conf)
        // delegate to control and release vc
        if self.serviceDelegate != nil {
            self.vc?.delegate = self.serviceDelegate
        }
                
        return self.vc
    }
    
    /// Creates online check request to the talkative online service
    /// - Returns: Request Obj
    public func createRequestForWidgetMatcher() -> URLRequest? {
        guard let conf = config else {
            NSLog("Talkative config is not correctly set!")
            return nil
        }
        let url = URL(string: conf.getUrlFromRegion() + "/api/ecs/v1/widget-matcher/" + conf.widgetUuid + "?path=" + conf.widgetPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return request
    }
    
    /// Creates online check request to the talkative online service
    /// - Returns: Request Obj
    public func createRequestForConfigLoad(configUuid: String) -> URLRequest? {
        guard let conf = config else {
            NSLog("Talkative config is not correctly set!")
            return nil
        }
        let url = URL(string: conf.getUrlFromRegion() + "/api/ecs/v1/config/" + configUuid)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return request
    }
    
    /// Checks online availability of the current users in system
    /// - Parameter completion: Closure with AvailabilityStatus enum where you can define states.
    public func onlineCheck(queueUuid: String, completion: @escaping (AvailabilityStatus) -> Void) {
        guard let widgetMatcherRequest = self.createRequestForWidgetMatcher() else {
            completion(.error(desc: "Request creation error!"))
            return
        }
        let widgetMatcherTask = URLSession.shared.dataTask(with: widgetMatcherRequest) { data, response, error in
            guard error == nil && data != nil else {
                print("Error during service call \(String(describing: error))")
                completion(.error(desc: "Error during service call \(String(describing: error))"))
                return
            }

            do {
                let obj = try JSONDecoder().decode(WidgetMatcherResponse.self, from: data!)
                
                guard let configRequest = self.createRequestForConfigLoad(configUuid: obj.configUuid) else {
                    completion(.error(desc: "Request creation error!"))
                    return
                }
                let configTask = URLSession.shared.dataTask(with: configRequest) { data, response, error in
                    guard error == nil && data != nil else {
                        print("Error during service call \(String(describing: error))")
                        completion(.error(desc: "Error during service call \(String(describing: error))"))
                        return
                    }

                    do {
                        let obj = try JSONDecoder().decode(ConfigResponse.self, from: data!)
                        
                        let status = obj.presences.first(where: {$0.queueUuid == queueUuid})?.status
                        
                        if (status == nil) {
                            completion(.error(desc: "Invalid queue uuid"))
                        } else if (status == "ONLINE") {
                            completion(.online)
                        } else {
                            completion(.offline)
                        }
                    } catch {
                        print("Error during JSON serialization: \(error.localizedDescription)")
                        completion(.error(desc: "Error during JSON serialization: \(error.localizedDescription)"))
                    }
                }
                
                configTask.resume()
                
            } catch {
                print("Error during JSON serialization: \(error.localizedDescription)")
                completion(.error(desc: "Error during JSON serialization: \(error.localizedDescription)"))
            }
        }

        widgetMatcherTask.resume();
    }
}

import Foundation
import UIKit

let talkativeServiceVersionNumber = "1.27.0"
let talkativeServerDomain: String! = "https://talkative-cdn.com/mobile-embed/0.0.5/index.html"

public class TalkativeManager {
    // General SDK Configuration
    public var config: TalkativeConfig?
    // Delegates for informing app about conversation status
    public weak var serviceDelegate: TalkativeServerDelegate?
    // Chat interface for starting the call
    private var vc: TalkativeViewController? = nil
    public static let shared = TalkativeManager()
    
    /// Starts intrecation immediately by giving TalkativeViewController to user where
    /// they can manage routing
    /// - Parameter type: Communication type .chat or .video
    /// - Returns: Optional view controller in the case of error
    public func startInteractionImmediately(type: CommunicationType) -> TalkativeViewController? {
        self.config?.type = type
        
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
    
    /// Starts interaction after checking online availability
    /// if there's someone online with requested communication type
    /// directly adds controller as a modal view to the current rootViewController
    /// - Parameter type: Communication type .chat or .video
    public func startInteractionWithCheck(type: CommunicationType) {
        self.config?.type = type
        let group = DispatchGroup()
        var currentStatus: AvailabilityStatus = .offline
        
        guard let conf = config else {
            NSLog("Talkative config is not correctly set!")
            return
        }
        
        group.enter()
        self.onlineCheck { status in
            currentStatus = status
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            if !currentStatus.isCommunicationAvailable(type: type) {
                print("Current Status \(currentStatus)")
                return
            }
            self.vc = TalkativeViewController(with: conf)
            // delegate to control and release vc
            if self.serviceDelegate != nil {
                self.vc?.delegate = self.serviceDelegate
            }
            
            if let root = UIApplication.shared.windows.first?.rootViewController {
                root.present(self.vc!, animated: true)
            }
        }
    }
    
    /// Creates online check request to the talkative online service
    /// - Returns: Request Obj
    public func createRequestForOnlineCheck() -> URLRequest? {
        guard let conf = config else {
            NSLog("Talkative config is not correctly set!")
            return nil
        }

        let url = URL(string: "https://" + conf.region + ".engage.app" + "/api/v1/controls/online")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "talkative_version": talkativeServiceVersionNumber,
            "talkative_company_uuid": conf.companyId,
            "talkative_queue_uuid": conf.queueId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [.prettyPrinted])
        } catch let error {
            print(error.localizedDescription)
        }
        
        return request
    }
    
    /// Checks online availability of the current users in system
    /// - Parameter completion: Closure with AvailabilityStatus enum where you can define states.
    public func onlineCheck(completion: @escaping (AvailabilityStatus) -> Void) {
        guard let req = self.createRequestForOnlineCheck() else {
            completion(.error(desc: "Request creation error!"))
            return
        }
        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            guard error == nil && data != nil else {
                
                print("Error during service call \(String(describing: error))")
                completion(.error(desc: "Error during service call \(String(describing: error))"))
                return
            }
            
            do {
                let obj = try JSONDecoder().decode(OnlineResponse.self, from: data!)
                if obj.status == "online" {
                    if obj.features.chat && obj.features.video {
                        completion(.chatAndVideo)
                    } else if obj.features.chat {
                        completion(.chatOnly)
                    } else if obj.features.video {
                        completion(.videoOnly)
                    } else {
                        completion(.offline)
                    }
                } else {
                    completion(.offline)
                }
            } catch {
                print("Error during JSON serialization: \(error.localizedDescription)")
                completion(.error(desc: "Error during JSON serialization: \(error.localizedDescription)"))
            }
        }

        task.resume();
    }
}

//
//  TalkativeManager.swift
//  CustomerScriptsEmbed
//
//  Created by mert on 01/09/2021.
//

import Foundation
import UIKit

let tutorialPage: String = "https://talkative.uk/"
let talkativeServiceVersionNumber = "1.27.0"

class TalkativeManager {
    // General SDK Configuration
    var config: TalkativeConfig?
    // Delegates for informing app about conversation status
    weak var serviceDelegate: TalkativeServerDelegate?
    // Chat interface for starting the call
    private var vc: TalkativeViewController? = nil
    static let shared = TalkativeManager()
    
    /// Starts intrecation immediately by giving TalkativeViewController to user where
    /// he can manage routing
    /// - Parameter type: Communication type .chat or .video
    /// - Returns: Optional view controller in the case of error
    func startInteractionImmediately(type: CommunicationType) -> TalkativeViewController? {
        self.config?.type = type
        
        guard let conf = config else {
            NSLog("Talkative config is not correctly set! Please visit \(tutorialPage) for more info.")
            return nil
        }
        
        self.vc = TalkativeViewController(with: conf)
        // if there's no delegate manager will act as a delegate and release vc
        // from the memory after finalizing interaction.
        if self.serviceDelegate != nil {
            self.vc?.delegate = self.serviceDelegate
        } else {
            self.vc?.delegate = self
        }
                
        return self.vc
    }
    
    /// Starts interaction after checking online availability
    /// if there's someone online with requested communication type
    /// directly adds controller as a modal view to the current rootViewController
    /// - Parameter type: Communication type .chat or .video
    func startInteractionWithCheck(type: CommunicationType) {
        self.config?.type = type
        let group = DispatchGroup()
        var currentStatus: AvailabilityStatus = .offline
        
        guard let conf = config else {
            NSLog("Talkative config is not correctly set! Please visit \(tutorialPage) for more info.")
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
            // if there's no delegate manager will act as a delegate and release vc
            // from the memory after finalizing interaction.
            if self.serviceDelegate != nil {
                self.vc?.delegate = self.serviceDelegate
            } else {
                self.vc?.delegate = self
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
            NSLog("Talkative config is not correctly set! Please visit \(tutorialPage) for more info.")
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
    func onlineCheck(completion: @escaping (AvailabilityStatus) -> Void) {
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

extension TalkativeManager: TalkativeServerDelegate {
    func onInteractionFinished() {
        print("TalkativeVC is released from memory")
        self.vc = nil
    }
}

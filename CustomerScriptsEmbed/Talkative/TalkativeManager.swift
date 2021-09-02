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
    
    func startInteraction(type: CommunicationType, shouldPresent: Bool = true) -> TalkativeViewController? {
        self.config?.type = type
        guard let conf = config else {
            NSLog("Talkative config is not correctly set! Please visit \(tutorialPage) for more info.")
            return nil
        }
        self.vc = TalkativeViewController(with: conf)
        self.vc?.delegate = serviceDelegate
        
        if shouldPresent {
            if let root = UIApplication.shared.windows.first?.rootViewController {
                root.present(self.vc!, animated: true)
            }
        }
        
        return self.vc
    }
    
    func onlineCheck(completion: @escaping (OnlineResponse?, Error?) -> Void) {
        guard let conf = config else {
            return
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
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil && data != nil else {
                print("Error during service call \(String(describing: error))")
                completion(nil, error)
                return
            }
            
            do {
                let obj = try JSONDecoder().decode(OnlineResponse.self, from: data!)
                completion(obj, nil)
            } catch {
                print("Error during JSON serialization: \(error.localizedDescription)")
                completion(nil, error)
            }
        }

        task.resume();
    }
}

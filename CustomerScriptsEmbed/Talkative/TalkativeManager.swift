//
//  TalkativeManager.swift
//  CustomerScriptsEmbed
//
//  Created by mert on 01/09/2021.
//

import Foundation
import UIKit

enum TalkativeError: Error {
    case configIsNotSet
}

class TalkativeManager {
    // General SDK Configuration
    var config: TalkativeConfig?
    // Delegates for informing app about conversation status
    weak var serviceDelegate: TalkativeServerDelegate?
    // Chat interface for starting the call
    private var vc: TalkativeViewController? = nil
    static let shared = TalkativeManager()
    
    func startChat(type: CommunicationType, completion: (() -> Void)? = nil) {
        self.config?.type = type
        guard let conf = config else {
            return
        }
        self.vc = TalkativeViewController(with: conf)
        self.vc?.delegate = serviceDelegate
        
        if let root = UIApplication.shared.windows.first?.rootViewController {
            root.present(self.vc!, animated: true, completion: completion)
        }
    }
    
    func onlineCheck(completion: @escaping (OnlineResponse?, Error?) -> Void) {
        guard let conf = config else {
            return
        }
        
        let session = URLSession.shared

        let url = URL(string: "https://" + conf.region + ".engage.app" + "/api/v1/controls/online")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json = [
            "talkative_version": conf.versionNumber,
            "talkative_company_uuid": conf.companyId,
            "talkative_queue_uuid": conf.queueId
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])

        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                // Serialize the data into an object
                do {
                    let json = try JSONDecoder().decode(OnlineResponse.self, from: data )
                    completion(json, nil)
                } catch {
                    print("Error during JSON serialization: \(error.localizedDescription)")
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        };

        task.resume();
    }
}

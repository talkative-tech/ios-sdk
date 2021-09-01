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
    var config: TalkativeConfiguration?
    private var vc: TalkativeViewController? = nil
    weak var serviceDelegate: TalkativeServerDelegate?
    static let shared = TalkativeManager()
//    {
//        didSet {
//            self.vc?.delegate = serviceDelegate
//        }
//    }
    
//    init(_ config: TalkativeConfiguration) {
//        self.config = config
//    }
    
    func startChat(type: CommunicationType, completion: (() -> Void)? = nil) {
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
            "talkative_version": "1.27.1",
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

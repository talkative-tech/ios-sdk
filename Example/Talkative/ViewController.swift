//
//  ViewController.swift
//  Talkative
//
//  Created by mert on 09/03/2021.
//  Copyright (c) 2021 mert. All rights reserved.
//

import UIKit
import Talkative

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TalkativeManager.shared.serviceDelegate = self
    }
    
    @IBAction func availabilityCheckClicked(_ sender: Any) {
        TalkativeManager.shared.onlineCheck { [weak self] status in
            var statusInfo = ""
            switch status {
            case .chatAndVideo:
                statusInfo = "Chat and Video available"
            case .chatOnly:
                statusInfo = "Only Chat is available"
            case .videoOnly:
                statusInfo = "Only Video is available"
            case .offline:
                statusInfo = "Currently Offline"
            case .error(let err):
                statusInfo = "There's an error \(err)"
            }
            print(statusInfo)
            DispatchQueue.main.async {
                self?.statusLabel.text = statusInfo
            }
        }
    }
    
    //This is the action linked to the Start Video button
    @IBAction func startVideoModalClicked(_ sender: Any) {
        TalkativeManager.shared.startInteractionWithCheck(type: .video)
    }
    //This is the action linked to the Start Chat button
    @IBAction func startChatModalClicked(_ sender: Any) {
        TalkativeManager.shared.startInteractionWithCheck(type: .chat)
    }
    
    @IBAction func startChatNavigationClicked(_ sender: Any) {
        if let vcToPush = TalkativeManager.shared.startInteractionImmediately(type: .chat) {
            self.navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
    
    @IBAction func startVideoNavigationClicked(_ sender: Any) {
        if let vcToPush = TalkativeManager.shared.startInteractionImmediately(type: .video) {
            self.navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
}

extension ViewController: TalkativeServerDelegate {
    func onReady() {
        print("webview is ready")
    }
    
    func onInteractionStart() {
        print("chat can start")
    }
    
    func onInteractionFinished() {
        print("chat finished")
    }
    
    func onQosFail(reason: QosFail) {
        print("Error: \(reason.localizedDescription)")
    }
}



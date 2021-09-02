import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TalkativeManager.shared.serviceDelegate = self
    }
    
    @IBAction func onlineCheck(_ sender: Any) {
        
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
    @IBAction func startVideo(_ sender: Any) {
        TalkativeManager.shared.startInteraction(type: .video)
    }
    
    //This is the action linked to the Start Chat button
    @IBAction func startChat(_ sender: Any) {
        TalkativeManager.shared.startInteraction(type: .chat)
    }
    
    @IBAction func startChatNavigation(_ sender: Any) {
        if let vcToPush = TalkativeManager.shared.startInteraction(type: .chat, shouldPresent: false) {
            self.navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
    
    @IBAction func startVideoNavigation(_ sender: Any) {
        if let vcToPush = TalkativeManager.shared.startInteraction(type: .video, shouldPresent: false) {
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
        print("chan finished")
    }
    
    func onQosFail(reason: QosFail) {
        print("Error: \(reason.localizedDescription)")
    }
}


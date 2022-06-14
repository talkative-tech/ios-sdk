import UIKit
import Talkative

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    public weak var vc: TalkativeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var interactionData: [InteractionDataEntry] = []
        let interactionData1 = try! JSONDecoder().decode(InteractionDataEntry.self, from: "{\"label\": \"Email\", \"name\": \"email\", \"type\": \"string\", \"data\": \"email@example.com\"}".data(using: .utf8)!)
        interactionData.append(interactionData1)
        
        // Override point for customization after application launch.
        TalkativeManager.shared.config = TalkativeConfig.defaultConfig(widgetUuid: "0682b469-b3f6-459a-8b6c-7e852071f066",
                                                                       region: "eu", interactionData: interactionData)
        TalkativeManager.shared.serviceDelegate = self
    }
    
    @IBAction func availabilityCheckClicked(_ sender: Any) {
        TalkativeManager.shared.onlineCheck(queueUuid: "0ec9ea36-5d0d-4d91-b63b-7325d855fca4") { [weak self] status in
            var statusInfo = ""
            switch status {
            case .online:
                statusInfo = "Currently Online"
            case .offline:
                statusInfo = "Currently Offline"
            case .error(let err):
                statusInfo = "There's an error \(err)"
            }
            DispatchQueue.main.async {
                self?.statusLabel.text = statusInfo
            }
        }
    }
    
    @IBAction func openWidget(_ sender: Any) {
        if (self.vc == nil) {
            if let vcToPush = TalkativeManager.shared.startInteraction() {
                self.vc = vcToPush
                self.navigationController?.pushViewController(vcToPush, animated: true)
            }
        } else {
            self.navigationController?.pushViewController(self.vc!, animated: true)
        }
    }
    
    @IBAction func startInteraction(_ sender: Any) {
        if (self.vc == nil) {
            if let vcToPush = TalkativeManager.shared.startInteraction(actionable: "Start Interaction Default Queue") {
                self.vc = vcToPush
                self.navigationController?.pushViewController(vcToPush, animated: true)
            }
        } else {
            self.navigationController?.pushViewController(self.vc!, animated: true)
        }
    }
}

extension ViewController: TalkativeServerDelegate {
    func onReady() {
        print("webview is ready")
    }
    
    func onInteractionStart() {
        print("interaction started")
    }
    
    func onInteractionFinished() {
        print("interaction finished")
        self.navigationController?.popViewController(animated: true)
        vc = nil;
    }
    
    func onQosFail() {
        print("Qos fail")
    }
    
    func onPresenceFail() {
        print("Presence fail")
    }
    
    func onCustomEvent(eventName: String) {
        print(eventName)
    }

    func onBeforeReady(qos: Qos) -> Bool {
        return true
    }
}


